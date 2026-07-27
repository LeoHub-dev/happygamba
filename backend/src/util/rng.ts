/** Deterministic RNG in [0, 1). Always non-negative. */
export function createRng(seedInit?: number): () => number {
  let seed =
    ((seedInit ?? (Date.now() ^ Math.floor(Math.random() * 0x7fffffff))) >>> 0) ||
    1;

  return () => {
    seed = (Math.imul(seed, 16807) + 1) % 2147483647;
    if (seed <= 0) seed += 2147483646;
    return seed / 2147483647;
  };
}
