import assert from "node:assert/strict";
import * as net from "node:net";
import test from "node:test";
import type { SubagentSnapshot } from "./src/domain.ts";
import {
  HerdrPaneController,
  type HerdrCommandRunner,
} from "./src/herdr/controller.ts";
import {
  isInsideHerdr,
  withoutHerdrEnvironment,
} from "./src/herdr/environment.ts";
import type { SubagentReadModel } from "./src/manager.ts";

function snapshot(id: string): SubagentSnapshot {
  return {
    id,
    origin: "model",
    backend: "pi",
    title: `Task ${id}`,
    prompt: "test",
    cwd: process.cwd(),
    status: "running",
    createdAt: Date.now(),
    generation: 1,
    meta: { backend: "pi", modelLabel: "openai/test", contextWindow: 1000 },
    usage: { tokens: 10, contextWindow: 1000 },
    transcript: [],
    liveTools: [],
    queued: [],
    finalText: "",
    turns: 0,
  };
}

function fakeView(snaps: SubagentSnapshot[]): SubagentReadModel {
  const items = new Map(snaps.map((snap) => [snap.id, snap]));
  return {
    list: () => [...items.values()],
    get: (id) => items.get(id),
    size: () => items.size,
    subscribe: () => () => {},
    subscribeTo: () => () => {},
    requestSend: () => {},
    requestAbort: () => {},
    setOnSettled: () => {},
  };
}

test("headless environments remove all Herdr caller context", () => {
  const clean = withoutHerdrEnvironment({
    PATH: "/bin",
    HOME: "/tmp/home",
    HERDR_ENV: "1",
    HERDR_PANE_ID: "w1:p1",
    HERDR_SOCKET_PATH: "/tmp/herdr.sock",
    HERDR_CUSTOM: "also removed",
  });
  assert.deepEqual(clean, { PATH: "/bin", HOME: "/tmp/home" });
  assert.equal(
    isInsideHerdr({
      HERDR_ENV: "1",
      HERDR_PANE_ID: "w1:p1",
      HERDR_SOCKET_PATH: "/tmp/herdr.sock",
    }),
    true,
  );
  assert.equal(isInsideHerdr({ HERDR_ENV: "1" }), false);
});

test("Herdr panes split right first, then stack down without stealing focus", async () => {
  const calls: string[][] = [];
  const viewerConnections: net.Socket[] = [];
  const viewerEnvironment = new Map<string, string>();
  let splitCount = 0;
  const runCommand: HerdrCommandRunner = async (args) => {
    calls.push([...args]);
    if (args[0] === "pane" && args[1] === "layout") {
      return {
        code: 0,
        stderr: "",
        stdout: JSON.stringify({
          result: {
            layout: {
              zoomed: false,
              panes: [
                { pane_id: "w1:p1", rect: { width: 220, height: 60 } },
                { pane_id: "w1:p2", rect: { width: 70, height: 60 } },
              ],
            },
          },
        }),
      };
    }
    if (args[0] === "pane" && args[1] === "split") {
      for (let index = 0; index < args.length; index++) {
        if (args[index] !== "--env") continue;
        const assignment = args[index + 1] ?? "";
        const equals = assignment.indexOf("=");
        if (equals > 0) {
          viewerEnvironment.set(assignment.slice(0, equals), assignment.slice(equals + 1));
        }
      }
      splitCount++;
      return {
        code: 0,
        stderr: "",
        stdout: JSON.stringify({ result: { pane: { pane_id: `w1:p${splitCount + 1}` } } }),
      };
    }
    if (args[0] === "pane" && args[1] === "run") {
      const connection = net.createConnection(viewerEnvironment.get("PI_SUBAGENT_BRIDGE")!);
      viewerConnections.push(connection);
      connection.once("connect", () => {
        connection.write(
          `${JSON.stringify({
            type: "hello",
            id: viewerEnvironment.get("PI_SUBAGENT_ID"),
            token: viewerEnvironment.get("PI_SUBAGENT_TOKEN"),
          })}\n`,
        );
      });
    }
    return { code: 0, stderr: "", stdout: "{}" };
  };

  const controller = new HerdrPaneController({
    parentPaneId: "w1:p1",
    parentSessionId: "parent-session",
    view: fakeView([snapshot("sa-1"), snapshot("sa-2")]),
    actions: { send: async () => {}, abort: () => {} },
    runCommand,
    viewerPath: "/tmp/viewer.mjs",
    nodePath: "/usr/bin/node",
    viewerHandshakeTimeoutMs: 500,
  });

  try {
    assert.equal(await controller.open("sa-1"), "w1:p2");
    assert.equal(await controller.open("sa-2"), "w1:p3");

    const splits = calls.filter((args) => args[0] === "pane" && args[1] === "split");
    assert.equal(splits.length, 2);
    assert.deepEqual(splits[0]?.slice(0, 8), [
      "pane",
      "split",
      "--pane",
      "w1:p1",
      "--direction",
      "right",
      "--ratio",
      "0.68",
    ]);
    assert.ok(splits[0]?.includes("--no-focus"));
    assert.deepEqual(splits[1]?.slice(0, 8), [
      "pane",
      "split",
      "--pane",
      "w1:p2",
      "--direction",
      "down",
      "--ratio",
      "0.5",
    ]);
    const tokens = splits.map((args) =>
      args.find((arg) => arg.startsWith("PI_SUBAGENT_TOKEN=")),
    );
    assert.equal(new Set(tokens).size, 2, "each viewer gets a distinct token");
    assert.ok(calls.some((args) => args[1] === "report-agent"));
    assert.ok(calls.some((args) => args[1] === "report-metadata"));
  } finally {
    await controller.close("sa-1");
    await controller.close("sa-2");
    await controller.closeAll();
    for (const connection of viewerConnections) connection.destroy();
  }
});

test("bridge rejects non-object JSON without crashing the host", async () => {
  let bridgeAddress = "";
  const clients: net.Socket[] = [];
  const runCommand: HerdrCommandRunner = async (args) => {
    if (args[1] === "layout") {
      return {
        code: 0,
        stderr: "",
        stdout: JSON.stringify({
          result: {
            layout: {
              zoomed: false,
              panes: [{ pane_id: "w1:p1", rect: { width: 200, height: 40 } }],
            },
          },
        }),
      };
    }
    if (args[1] === "split") {
      const assignment = args.find((arg) =>
        arg.startsWith("PI_SUBAGENT_BRIDGE="),
      );
      bridgeAddress = assignment?.slice("PI_SUBAGENT_BRIDGE=".length) ?? "";
      return {
        code: 0,
        stderr: "",
        stdout: JSON.stringify({ result: { pane: { pane_id: "w1:p2" } } }),
      };
    }
    if (args[1] === "run") {
      const client = net.createConnection(bridgeAddress);
      clients.push(client);
      client.once("connect", () => client.write("null\n"));
    }
    return { code: 0, stderr: "", stdout: "{}" };
  };
  const controller = new HerdrPaneController({
    parentPaneId: "w1:p1",
    parentSessionId: "parent-session",
    view: fakeView([snapshot("sa-1")]),
    actions: { send: async () => {}, abort: () => {} },
    runCommand,
    viewerHandshakeTimeoutMs: 50,
  });
  await assert.rejects(controller.open("sa-1"), /viewer did not start/);
  await controller.closeAll();
  for (const client of clients) client.destroy();
});

test("Herdr pane creation refuses unsafe narrow layouts", async () => {
  const runCommand: HerdrCommandRunner = async (args) => ({
    code: 0,
    stderr: "",
    stdout:
      args[1] === "layout"
        ? JSON.stringify({
            result: {
              layout: {
                zoomed: false,
                panes: [{ pane_id: "w1:p1", rect: { width: 100, height: 40 } }],
              },
            },
          })
        : "{}",
  });
  const controller = new HerdrPaneController({
    parentPaneId: "w1:p1",
    parentSessionId: "parent-session",
    view: fakeView([snapshot("sa-1")]),
    actions: { send: async () => {}, abort: () => {} },
    runCommand,
    viewerHandshakeTimeoutMs: 0,
  });
  await assert.rejects(controller.open("sa-1"), /too narrow/);
  await controller.closeAll();
});
