// Polyfill minimal browser globals for Node test environment
if (typeof globalThis.localStorage === "undefined") {
  const store = new Map<string, string>();
  // @ts-expect-error Mock minimal localStorage interface for vitest
  globalThis.localStorage = {
    getItem: (key: string) => store.get(key) ?? null,
    setItem: (key: string, value: string) => store.set(key, String(value)),
    removeItem: (key: string) => store.delete(key),
    clear: () => store.clear(),
    key: (index: number) => Array.from(store.keys())[index] ?? null,
    get length() {
      return store.size;
    },
  };
}
