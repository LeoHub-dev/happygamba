const SUITS = ['♠', '♥', '♦', '♣'];
const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

export interface Card {
  rank: string;
  suit: string;
}

export function cardValue(card: Card): number {
  if (card.rank === 'A') return 11;
  if (['K', 'Q', 'J'].includes(card.rank)) return 10;
  return parseInt(card.rank, 10);
}

export function handTotal(cards: Card[]): number {
  let total = cards.reduce((s, c) => s + cardValue(c), 0);
  let aces = cards.filter((c) => c.rank === 'A').length;
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  return total;
}

export function randomCard(rng: () => number): Card {
  return {
    rank: RANKS[Math.floor(rng() * RANKS.length)],
    suit: SUITS[Math.floor(rng() * SUITS.length)],
  };
}

export function generateHandForOutcome(
  target: 'win' | 'lose' | 'push',
  rng: () => number
): { player: Card[]; dealer: Card[] } {
  for (let attempt = 0; attempt < 50; attempt++) {
    const player = [randomCard(rng), randomCard(rng)];
    const dealer = [randomCard(rng), randomCard(rng)];
    const pTotal = handTotal(player);
    const dTotal = handTotal(dealer);

    if (target === 'win' && pTotal >= 17 && pTotal <= 21 && dTotal < pTotal) {
      return { player, dealer };
    }
    if (target === 'lose' && dTotal >= 17 && dTotal > pTotal && pTotal <= 21) {
      return { player, dealer };
    }
    if (target === 'push' && pTotal === dTotal && pTotal >= 17) {
      return { player, dealer };
    }
  }

  return {
    player: [
      { rank: '10', suit: '♠' },
      { rank: '9', suit: '♥' },
    ],
    dealer: [
      { rank: '10', suit: '♦' },
      { rank: '8', suit: '♣' },
    ],
  };
}
