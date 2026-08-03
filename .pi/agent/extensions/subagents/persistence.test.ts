import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import test from "node:test";
import type { SubagentSnapshot } from "./src/domain.ts";
import {
  SubagentRunStore,
  subagentDeliveryId,
} from "./src/persistence.ts";

function snapshot(
  status: SubagentSnapshot["status"] = "running",
): SubagentSnapshot {
  return {
    id: "sa-recovery1",
    origin: "model",
    backend: "claude",
    title: "recovery test",
    prompt: "finish the recovery test",
    cwd: "/tmp/project",
    status,
    createdAt: 1_000,
    generation: 1,
    settledAt: status === "running" ? undefined : 2_000,
    meta: {
      backend: "claude",
      modelLabel: "sonnet",
      nativeSessionId: "11111111-1111-4111-8111-111111111111",
      sessionFilePath: "/tmp/claude-session.jsonl",
    },
    usage: { tokens: 42, contextWindow: 200_000 },
    transcript: [{ kind: "user", text: "finish the recovery test" }],
    liveAssistant:
      status === "running" ? { text: "working", thinking: "" } : undefined,
    liveTools: [],
    queued: [],
    finalText: status === "done" ? "finished" : "",
    turns: status === "done" ? 1 : 0,
  };
}

function withTempStore(
  run: (options: { root: string; store: SubagentRunStore }) => void,
) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "subagent-store-"));
  try {
    run({
      root,
      store: new SubagentRunStore(root, "parent-session", "/tmp/parent.jsonl"),
    });
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

test("running snapshots restore conservatively as recoverable", () => {
  withTempStore(({ root, store }) => {
    const running = snapshot();
    store.register(running, { model: "sonnet", reasoningEffort: "high" });
    store.close([running]);

    const restored = new SubagentRunStore(
      root,
      "parent-session",
      "/tmp/parent.jsonl",
    ).load();
    assert.equal(restored.length, 1);
    assert.equal(restored[0]?.snapshot.status, "recoverable");
    assert.match(restored[0]?.snapshot.errorText ?? "", /Parent session ended/);
    assert.equal(restored[0]?.snapshot.liveAssistant, undefined);
    assert.equal(restored[0]?.spec.model, "sonnet");
  });
});

test("terminal results keep a stable delivery receipt", () => {
  withTempStore(({ root, store }) => {
    const done = snapshot("done");
    store.register(done, { model: "sonnet" });
    const deliveryId = store.saveTerminal(done);
    assert.equal(deliveryId, subagentDeliveryId(done));

    const reopened = new SubagentRunStore(root, "parent-session");
    const [pending] = reopened.load();
    assert.equal(pending?.outbox[0]?.state, "pending");
    assert.equal(pending?.outbox[0]?.deliveryId, deliveryId);

    reopened.markDelivered(new Set([deliveryId!]));
    const [delivered] = new SubagentRunStore(
      root,
      "parent-session",
    ).load();
    assert.equal(delivered?.outbox[0]?.state, "delivered");
  });
});

test("successive generations keep independent pending results", () => {
  withTempStore(({ root, store }) => {
    const first = snapshot("done");
    store.register(first, {});
    store.saveTerminal(first);
    const second = {
      ...first,
      generation: 2,
      settledAt: 3_000,
      finalText: "finished again",
    };
    store.saveTerminal(second);

    const [record] = new SubagentRunStore(root, "parent-session").load();
    assert.equal(record?.outbox.length, 2);
    assert.equal(
      new Set(record?.outbox.map((delivery) => delivery.deliveryId)).size,
      2,
    );
    assert.deepEqual(
      record?.outbox.map((delivery) => delivery.snapshot.finalText),
      ["finished", "finished again"],
    );
  });
});

test("a corrupt run record does not hide valid records", () => {
  withTempStore(({ root, store }) => {
    const done = snapshot("done");
    store.register(done, {});
    store.close([done]);
    const directory = path.join(
      root,
      "state",
      "subagents",
      "v1",
      "parent-session",
    );
    fs.writeFileSync(path.join(directory, "corrupt.json"), "{not json");

    const restored = new SubagentRunStore(root, "parent-session").load();
    assert.deepEqual(restored.map((record) => record.snapshot.id), [done.id]);
  });
});
