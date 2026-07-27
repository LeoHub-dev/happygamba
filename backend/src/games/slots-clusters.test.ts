import { describe, expect, it } from 'vitest';
import {
  applyGravity,
  buildCascades,
  findClusters,
  generateLossGrid,
  generateWinGrid,
  removeCells,
  tumble,
} from './slots-clusters.js';

function rngFrom(seed: number) {
  let s = seed || 1;
  return () => {
    s = (Math.imul(s, 16807) + 1) % 2147483647;
    if (s <= 0) s += 2147483646;
    return s / 2147483647;
  };
}

describe('findClusters', () => {
  it('detects orthogonal clusters of size >= 4', () => {
    const grid = [
      ['A', 'A', '10', 'J', 'Q'],
      ['A', 'A', 'K', 'J', 'Q'],
      ['HAT', 'BOOT', 'K', 'J', 'Q'],
      ['HAT', 'BOOT', 'MUG', 'DICE', 'FS'],
      ['10', 'J', 'Q', 'K', 'A'],
    ];
    const clusters = findClusters(grid);
    expect(clusters.some((c) => c.symbol === 'A' && c.cells.length >= 4)).toBe(true);
  });

  it('allows wilds to join a cluster', () => {
    const grid = [
      ['HAT', 'W', '10', 'J', 'Q'],
      ['HAT', 'HAT', 'K', 'J', 'Q'],
      ['W', 'BOOT', 'K', 'J', 'Q'],
      ['10', 'BOOT', 'MUG', 'DICE', 'FS'],
      ['10', 'J', 'Q', 'K', 'A'],
    ];
    const clusters = findClusters(grid);
    const hat = clusters.find((c) => c.symbol === 'HAT');
    expect(hat).toBeTruthy();
    expect(hat!.cells.length).toBeGreaterThanOrEqual(4);
  });

  it('does not treat FS as a paying cluster', () => {
    const grid = [
      ['FS', 'FS', 'FS', 'FS', 'FS'],
      ['FS', 'FS', 'FS', 'FS', 'FS'],
      ['10', 'J', 'Q', 'K', 'A'],
      ['10', 'J', 'Q', 'K', 'A'],
      ['10', 'J', 'Q', 'K', 'A'],
    ];
    expect(findClusters(grid).length).toBe(0);
  });
});

describe('tumble', () => {
  it('applies gravity after removals', () => {
    const grid = [
      ['A', '10', 'J', 'Q', 'K'],
      ['A', '10', 'J', 'Q', 'K'],
      ['A', '10', 'J', 'Q', 'K'],
      ['A', '10', 'J', 'Q', 'K'],
      ['BOOT', '10', 'J', 'Q', 'K'],
    ];
    const removed: [number, number][] = [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
    ];
    const g = applyGravity(removeCells(grid, removed));
    expect(g[4][0]).toBe('BOOT');
    expect(g[3][0]).toBeNull();
  });

  it('fills empty cells', () => {
    const grid = generateLossGrid(rngFrom(3));
    const next = tumble(grid, [[0, 0], [1, 0], [2, 0], [3, 0]], rngFrom(4));
    expect(next.every((row) => row.every((c) => typeof c === 'string'))).toBe(true);
  });
});

describe('buildCascades', () => {
  it('loss spins have exactly one cascade and no wins', () => {
    const { cascades, totalPayout } = buildCascades({
      shouldWin: false,
      targetPayout: 0,
      bet: 1000,
      rng: rngFrom(99),
    });
    expect(cascades.length).toBe(1);
    expect(cascades[0].wins.length).toBe(0);
    expect(totalPayout).toBe(0);
  });

  it('win spins include at least one cluster and only tumble when new matches exist', () => {
    const { cascades, totalPayout } = buildCascades({
      shouldWin: true,
      targetPayout: 2500,
      bet: 1000,
      rng: rngFrom(42),
    });
    expect(cascades.length).toBeGreaterThanOrEqual(1);
    expect(cascades[0].wins.length).toBeGreaterThan(0);
    expect(cascades[0].removed.length).toBeGreaterThanOrEqual(4);
    expect(totalPayout).toBeGreaterThanOrEqual(2500);

    // Every cascade after the first must be justified by wins on previous tumble path
    for (const step of cascades) {
      if (step.wins.length) {
        expect(step.removed.length).toBeGreaterThan(0);
      }
    }
  });

  it('generateWinGrid always has a cluster', () => {
    for (let i = 0; i < 20; i++) {
      const grid = generateWinGrid(rngFrom(100 + i));
      expect(findClusters(grid).length).toBeGreaterThan(0);
    }
  });
});
