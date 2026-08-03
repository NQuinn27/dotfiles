import assert from "node:assert/strict";
import test from "node:test";
import { createDeferredResultDelivery } from "./src/result-delivery.ts";

test("a result consumed by a later wait is not delivered", () => {
  const delivery = createDeferredResultDelivery<{
    id: string;
    output: string;
  }>();

  delivery.defer({ id: "sa-1", output: "done" });
  delivery.consume(["sa-1"]);

  assert.deepEqual(delivery.drain(), []);
});

test("unconsumed results are delivered once in settlement order", () => {
  const delivery = createDeferredResultDelivery<{ id: string }>();
  const first = { id: "sa-1" };
  const second = { id: "sa-2" };

  delivery.defer(first);
  delivery.defer(second);

  assert.deepEqual(delivery.drain(), [first, second]);
  assert.deepEqual(delivery.drain(), []);
});

test("separate generations of one subagent are retained", () => {
  const delivery = createDeferredResultDelivery<{
    id: string;
    generation: number;
  }>((result) => `${result.id}:${result.generation}`);
  const first = { id: "sa-1", generation: 1 };
  const second = { id: "sa-1", generation: 2 };

  delivery.defer(first);
  delivery.defer(second);
  delivery.consumeKeys(["sa-1:2"]);

  assert.deepEqual(delivery.drain(), [first]);
});
