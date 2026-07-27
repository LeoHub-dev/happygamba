import cors from 'cors';
import express from 'express';
import { authMiddleware, type AuthRequest } from './auth/middleware.js';
import { getUserProfile, loginUser, registerUser, syncSocialUser } from './auth/service.js';
import { getDb } from './db.js';
import { startBlackjack, blackjackAction } from './games/blackjack.js';
import { spinSlots } from './games/slots.js';
import {
  claimDailyBonus,
  getLiveBetsFeed,
  handleRevenueCatWebhook,
} from './monetization.js';

const app = express();
const PORT = process.env.PORT ?? 8000;

app.use(cors());
app.use(express.json());

getDb();

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'happygamba-api' });
});

app.post('/auth/register', (req, res) => {
  try {
    const { username, password } = req.body;
    const result = registerUser(username, password);
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.post('/auth/login', (req, res) => {
  try {
    const { username, password } = req.body;
    const result = loginUser(username, password);
    res.json(result);
  } catch (e) {
    res.status(401).json({ error: (e as Error).message });
  }
});

app.post('/auth/sync', (req, res) => {
  try {
    const { firebaseUid, displayName, provider, avatarUrl } = req.body;
    if (!firebaseUid || !provider) {
      return res.status(400).json({ error: 'firebaseUid and provider required' });
    }
    const result = syncSocialUser(
      firebaseUid,
      displayName ?? 'Player',
      provider,
      avatarUrl
    );
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.get('/user/profile', authMiddleware, (req: AuthRequest, res) => {
  try {
    const profile = getUserProfile(req.userId!);
    res.json(profile);
  } catch (e) {
    res.status(404).json({ error: (e as Error).message });
  }
});

app.post('/games/slots/spin', authMiddleware, (req: AuthRequest, res) => {
  try {
    const { bet } = req.body;
    const result = spinSlots(req.userId!, bet);
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.post('/games/blackjack/start', authMiddleware, (req: AuthRequest, res) => {
  try {
    const { bet } = req.body;
    const result = startBlackjack(req.userId!, bet);
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.post('/games/blackjack/action', authMiddleware, (req: AuthRequest, res) => {
  try {
    const { sessionId, action } = req.body;
    const result = blackjackAction(req.userId!, sessionId, action);
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.post('/economy/daily-bonus', authMiddleware, (req: AuthRequest, res) => {
  try {
    const { rewarded } = req.body;
    const result = claimDailyBonus(req.userId!, rewarded);
    res.json(result);
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
});

app.get('/feed/live-bets', (_req, res) => {
  res.json(getLiveBetsFeed());
});

app.post('/webhooks/revenuecat', (req, res) => {
  const result = handleRevenueCatWebhook(req.body);
  res.json(result);
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`HappyGamba API running on http://localhost:${PORT}`);
  });
}

export default app;
