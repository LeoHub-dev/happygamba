const ROWS = 5;
const COLS = 5;
const MIN_CLUSTER = 4;

export const PAY_SYMBOLS = ['10', 'J', 'Q', 'K', 'A', 'HAT', 'BOOT', 'MUG', 'DICE'] as const;
export const WILD = 'W';
export const SCATTER = 'FS';

export type Cell = [number, number];

export interface ClusterWin {
  symbol: string;
  cells: Cell[];
  payout: number;
  mult: number;
}

const NEIGHBORS: Cell[] = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
];

function inBounds(r: number, c: number) {
  return r >= 0 && r < ROWS && c >= 0 && c < COLS;
}

function isPayOrWild(sym: string) {
  return sym === WILD || (PAY_SYMBOLS as readonly string[]).includes(sym);
}

/**
 * Find connected clusters (orthogonal) of the same pay symbol.
 * Wilds (`W`) join any adjacent pay-symbol cluster.
 * Scatter (`FS`) never forms clusters.
 * Wild cells may participate in evaluation of multiple symbols, but callers
 * usually union cells for removal.
 */
export function findClusters(grid: string[][]): { symbol: string; cells: Cell[] }[] {
  const visitedPay = Array.from({ length: ROWS }, () => Array(COLS).fill(false));
  const clusters: { symbol: string; cells: Cell[] }[] = [];

  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (visitedPay[r][c]) continue;
      const start = grid[r][c];
      if (!isPayOrWild(start) || start === WILD) continue;

      const cells: Cell[] = [];
      const local = Array.from({ length: ROWS }, () => Array(COLS).fill(false));
      const queue: Cell[] = [[r, c]];
      local[r][c] = true;

      while (queue.length) {
        const [cr, cc] = queue.shift()!;
        const cur = grid[cr][cc];
        if (cur !== start && cur !== WILD) continue;
        cells.push([cr, cc]);
        if (cur === start) visitedPay[cr][cc] = true;

        for (const [dr, dc] of NEIGHBORS) {
          const nr = cr + dr;
          const nc = cc + dc;
          if (!inBounds(nr, nc) || local[nr][nc]) continue;
          const n = grid[nr][nc];
          if (n === start || n === WILD) {
            local[nr][nc] = true;
            queue.push([nr, nc]);
          }
        }
      }

      if (cells.length >= MIN_CLUSTER) {
        clusters.push({ symbol: start, cells });
      }
    }
  }

  return clusters;
}

export function allWinningCells(clusters: { cells: Cell[] }[]): Cell[] {
  const seen = new Set<string>();
  const out: Cell[] = [];
  for (const cl of clusters) {
    for (const [r, c] of cl.cells) {
      const key = `${r},${c}`;
      if (!seen.has(key)) {
        seen.add(key);
        out.push([r, c]);
      }
    }
  }
  return out;
}

/** Gravity: symbols fall down per column; empties become null. */
export function applyGravity(grid: (string | null)[][]): (string | null)[][] {
  const next = Array.from({ length: ROWS }, () => Array<string | null>(COLS).fill(null));
  for (let c = 0; c < COLS; c++) {
    const stack: string[] = [];
    for (let r = ROWS - 1; r >= 0; r--) {
      const v = grid[r][c];
      if (v != null) stack.push(v);
    }
    let r = ROWS - 1;
    for (const v of stack) {
      next[r][c] = v;
      r--;
    }
  }
  return next;
}

export function fillEmpties(
  grid: (string | null)[][],
  rng: () => number,
  pool: readonly string[] = [...PAY_SYMBOLS, WILD, SCATTER]
): string[][] {
  return grid.map((row) =>
    row.map((cell) => {
      if (cell != null) return cell;
      return pool[Math.floor(rng() * pool.length)];
    })
  );
}

export function removeCells(grid: string[][], cells: Cell[]): (string | null)[][] {
  const next = grid.map((row) => [...row]) as (string | null)[][];
  for (const [r, c] of cells) next[r][c] = null;
  return next;
}

export function tumble(
  grid: string[][],
  removed: Cell[],
  rng: () => number
): string[][] {
  return fillEmpties(applyGravity(removeCells(grid, removed)), rng);
}

export function randomGrid(
  rng: () => number,
  pool: readonly string[] = [...PAY_SYMBOLS, WILD, SCATTER]
): string[][] {
  const grid: string[][] = [];
  for (let r = 0; r < ROWS; r++) {
    const row: string[] = [];
    for (let c = 0; c < COLS; c++) {
      row.push(pool[Math.floor(rng() * pool.length)]);
    }
    grid.push(row);
  }
  return grid;
}

/** Build a loss grid with no paying clusters (retry / break). */
export function generateLossGrid(rng: () => number): string[][] {
  for (let attempt = 0; attempt < 40; attempt++) {
    const grid = randomGrid(rng);
    if (findClusters(grid).length === 0) return grid;
  }
  // Fallback: checker-ish pattern without large groups
  const grid = randomGrid(rng);
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      grid[r][c] = PAY_SYMBOLS[(r + c) % PAY_SYMBOLS.length];
    }
  }
  return grid;
}

function plantCluster(
  grid: string[][],
  symbol: string,
  size: number,
  rng: () => number
): Cell[] {
  const startR = Math.floor(rng() * ROWS);
  const startC = Math.floor(rng() * COLS);
  const cells: Cell[] = [[startR, startC]];
  const used = new Set<string>([`${startR},${startC}`]);
  grid[startR][startC] = symbol;

  while (cells.length < size) {
    const frontier = cells[Math.floor(rng() * cells.length)];
    const [dr, dc] = NEIGHBORS[Math.floor(rng() * NEIGHBORS.length)];
    const nr = frontier[0] + dr;
    const nc = frontier[1] + dc;
    if (!inBounds(nr, nc)) continue;
    const key = `${nr},${nc}`;
    if (used.has(key)) continue;
    used.add(key);
    grid[nr][nc] = rng() < 0.15 ? WILD : symbol;
    cells.push([nr, nc]);
    if (cells.length >= size) break;
    // Prevent infinite loop on unlucky RNG
    if (used.size > ROWS * COLS) break;
  }
  return cells;
}

export function generateWinGrid(rng: () => number): string[][] {
  let grid = generateLossGrid(rng);
  const symbol = PAY_SYMBOLS[Math.floor(rng() * PAY_SYMBOLS.length)];
  const size = 4 + Math.floor(rng() * 4); // 4–7
  plantCluster(grid, symbol, size, rng);

  // Occasionally plant a second smaller cluster
  if (rng() < 0.35) {
    const symbol2 = PAY_SYMBOLS[Math.floor(rng() * PAY_SYMBOLS.length)];
    plantCluster(grid, symbol2, 4, rng);
  }

  // Ensure at least one cluster exists
  if (findClusters(grid).length === 0) {
    plantCluster(grid, symbol, 5, rng);
  }
  return grid;
}

function clusterPayoutShare(
  clusters: { symbol: string; cells: Cell[] }[],
  stepBudget: number
): ClusterWin[] {
  if (!clusters.length || stepBudget <= 0) return [];
  const weights = clusters.map((c) => c.cells.length);
  const totalW = weights.reduce((a, b) => a + b, 0);
  let remaining = stepBudget;
  return clusters.map((cl, i) => {
    const isLast = i === clusters.length - 1;
    const payout = isLast
      ? remaining
      : Math.max(1, Math.floor((stepBudget * weights[i]) / totalW));
    if (!isLast) remaining -= payout;
    return {
      symbol: cl.symbol,
      cells: cl.cells,
      payout,
      mult: payout / Math.max(stepBudget, 1),
    };
  });
}

export interface CascadeStep {
  grid: string[][];
  wins: ClusterWin[];
  removed: Cell[];
}

/**
 * Build cascade chain.
 * - Extra tumbles only when removing winners creates new clusters (Hacksaw-style).
 * - `targetPayout` is split across cascade steps that have wins.
 */
export function buildCascades(options: {
  shouldWin: boolean;
  targetPayout: number;
  bet: number;
  rng: () => number;
  maxCascades?: number;
}): { cascades: CascadeStep[]; totalPayout: number } {
  const { shouldWin, targetPayout, bet, rng, maxCascades = 8 } = options;
  const cascades: CascadeStep[] = [];

  if (!shouldWin || targetPayout <= 0) {
    const grid = generateLossGrid(rng);
    cascades.push({ grid, wins: [], removed: [] });
    return { cascades, totalPayout: 0 };
  }

  let grid = generateWinGrid(rng);
  let remainingPayout = targetPayout;
  let step = 0;

  while (step < maxCascades) {
    const clusters = findClusters(grid);
    if (!clusters.length) {
      if (step === 0) {
        // Force a win cluster on first step if RNG failed
        grid = generateWinGrid(rng);
        continue;
      }
      break;
    }

    const removed = allWinningCells(clusters);
    // Leave a bit of payout for later cascades if more likely
    const stepsLeftHint = Math.max(1, maxCascades - step);
    const share =
      step === 0
        ? Math.max(1, Math.floor(remainingPayout * (0.45 + rng() * 0.25)))
        : Math.max(1, Math.floor(remainingPayout / Math.min(stepsLeftHint, 3)));
    const stepBudget = Math.min(remainingPayout, share);
    const wins = clusterPayoutShare(clusters, stepBudget);
    remainingPayout -= wins.reduce((s, w) => s + w.payout, 0);

    cascades.push({
      grid: grid.map((row) => [...row]),
      wins,
      removed,
    });

    // Tumble only if we expect possible further wins and budget remains OR randomly continue chain
    const next = tumble(grid, removed, rng);
    const nextClusters = findClusters(next);
    step++;

    if (!nextClusters.length) {
      // No new matches → stop (no fake extra roll)
      break;
    }

    // Continue tumble with remaining payout; if budget exhausted, still show visual tumble with 0 payout wins once more max
    if (remainingPayout <= 0) {
      cascades.push({
        grid: next.map((row) => [...row]),
        wins: nextClusters.map((cl) => ({
          symbol: cl.symbol,
          cells: cl.cells,
          payout: 0,
          mult: 0,
        })),
        removed: allWinningCells(nextClusters),
      });
      break;
    }

    grid = next;
  }

  // If somehow no cascades, force one winning step
  if (!cascades.length) {
    const g = generateWinGrid(rng);
    const clusters = findClusters(g);
    const removed = allWinningCells(clusters);
    cascades.push({
      grid: g,
      wins: clusterPayoutShare(clusters, targetPayout),
      removed,
    });
  }

  const totalPayout = cascades.reduce(
    (sum, c) => sum + c.wins.reduce((s, w) => s + w.payout, 0),
    0
  );

  // Ensure we don't under-pay vs economy target on a win (top up first win)
  if (totalPayout < targetPayout && cascades[0]?.wins.length) {
    const deficit = targetPayout - totalPayout;
    cascades[0].wins[0].payout += deficit;
  }

  return {
    cascades,
    totalPayout: Math.max(totalPayout, shouldWin ? Math.max(targetPayout, bet) : 0),
  };
}
