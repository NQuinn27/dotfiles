import assert from "node:assert/strict";
import test from "node:test";
import type { SessionEntry } from "@earendil-works/pi-coding-agent";
import {
  buildHerdrTitleCommands,
  buildOpeningTranscript,
  cleanGeneratedTitle,
  countUserMessages,
  restoreOwnership,
} from "../auto-session-name.ts";

function userEntry(
  id: string,
  content: string,
  parentId: string | null,
): SessionEntry {
  return {
    type: "message",
    id,
    parentId,
    timestamp: "2026-01-01T00:00:00.000Z",
    message: {
      role: "user",
      content,
      timestamp: 0,
    },
  };
}

test("cleanGeneratedTitle removes model formatting and limits length", () => {
  assert.equal(
    cleanGeneratedTitle(
      '```text\nSession title: "Improve Herdr Session Naming."\n```',
    ),
    "Improve Herdr Session Naming",
  );
  assert.ok(cleanGeneratedTitle("A ".repeat(80)).length <= 60);
});

test("opening transcript stops before later user messages", () => {
  const entries = [
    userEntry("one", "Create an automatic session naming extension", null),
    {
      type: "session_info",
      id: "info",
      parentId: "one",
      timestamp: "2026-01-01T00:00:01.000Z",
      name: "Temporary",
    },
    userEntry("two", "This must not be included", "info"),
  ] satisfies SessionEntry[];

  assert.equal(countUserMessages(entries), 2);
  assert.equal(
    buildOpeningTranscript(entries, 1),
    "User: Create an automatic session naming extension",
  );
});

test("opening transcript reserves room for all selected user turns", () => {
  const entries = [
    userEntry("one", "First goal", null),
    userEntry("two", "Second decision", "one"),
    userEntry("three", "Third refinement", "two"),
  ];

  assert.match(buildOpeningTranscript(entries, 3), /First goal/);
  assert.match(buildOpeningTranscript(entries, 3), /Second decision/);
  assert.match(buildOpeningTranscript(entries, 3), /Third refinement/);
});

test("Herdr updates both pane metadata and the sidebar tab label", () => {
  assert.deepEqual(
    buildHerdrTitleCommands("Fix Herdr Naming", "/tmp/project", 42, {
      HERDR_ENV: "1",
      HERDR_PANE_ID: "w1:p9",
      HERDR_TAB_ID: "w1:t4",
    }),
    [
      [
        "pane",
        "report-metadata",
        "w1:p9",
        "--source",
        "pi-auto-session-name",
        "--applies-to-source",
        "herdr:pi",
        "--title",
        "Fix Herdr Naming",
        "--seq",
        "42",
      ],
      ["tab", "rename", "w1:t4", "Fix Herdr Naming"],
    ],
  );
});

test("Herdr clears pane metadata and resets an unnamed tab to the directory", () => {
  assert.deepEqual(
    buildHerdrTitleCommands(undefined, "/tmp/project", 43, {
      HERDR_ENV: "1",
      HERDR_PANE_ID: "w1:p9",
      HERDR_TAB_ID: "w1:t4",
    }),
    [
      [
        "pane",
        "report-metadata",
        "w1:p9",
        "--source",
        "pi-auto-session-name",
        "--applies-to-source",
        "herdr:pi",
        "--clear-title",
        "--seq",
        "43",
      ],
      ["tab", "rename", "w1:t4", "project"],
    ],
  );
});

test("Herdr commands stay disabled outside a managed pane", () => {
  assert.deepEqual(
    buildHerdrTitleCommands("Ignored", "/tmp/project", 44, {}),
    [],
  );
});

test("ownership detects a later manual rename even when the text is unchanged", () => {
  const name = "Improve Herdr Session Naming";
  const automaticEntries = [
    {
      type: "session_info",
      id: "name",
      parentId: null,
      timestamp: "2026-01-01T00:00:00.000Z",
      name,
    },
    {
      type: "custom",
      id: "state",
      parentId: "name",
      timestamp: "2026-01-01T00:00:01.000Z",
      customType: "auto-session-name",
      data: { version: 1, stage: 1, name },
    },
  ] satisfies SessionEntry[];

  assert.equal(restoreOwnership(automaticEntries, name).manualOverride, false);

  const manuallyRenamed = [
    ...automaticEntries,
    {
      type: "session_info" as const,
      id: "manual",
      parentId: "state",
      timestamp: "2026-01-01T00:00:02.000Z",
      name,
    },
  ];
  assert.equal(restoreOwnership(manuallyRenamed, name).manualOverride, true);
});
