export function createDeferredResultDelivery<T extends { id: string }>(
  keyOf: (result: T) => string = (result) => result.id,
) {
  const pending = new Map<string, T>();

  return {
    defer(result: T) {
      pending.set(keyOf(result), result);
    },
    /** Consume every pending generation belonging to these subagent ids. */
    consume(ids: Iterable<string>) {
      const wanted = new Set(ids);
      for (const [key, result] of pending) {
        if (wanted.has(result.id)) pending.delete(key);
      }
    },
    /** Consume only specific delivery generations. */
    consumeKeys(keys: Iterable<string>) {
      for (const key of keys) pending.delete(key);
    },
    drain() {
      const results = [...pending.values()];
      pending.clear();
      return results;
    },
    clear() {
      pending.clear();
    },
  };
}
