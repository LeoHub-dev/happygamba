# HappyGamba

App móvil Flutter de casino con moneda ficticia — entretenimiento, no apuestas reales.

## Estructura

```
happygamba/
├── apps/mobile/     # Flutter app (iOS, Android, Web)
├── backend/         # API Node.js + SQLite
└── docs/            # Documentación economía
```

## Requisitos

- Flutter 3.x
- Node.js 20+

## Backend

```bash
cd backend
npm install
npm run dev          # http://localhost:3000
npm test             # tests economía
```

## Mobile

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Auth

- Registro/login con usuario + contraseña (sin email)
- Google / Apple via `/auth/sync` (demo mode en dev)

## Monetización

- AdMob (banner, interstitial, rewarded)
- RevenueCat (monedas, VIP, sin ads)
- Webhook: `POST /webhooks/revenuecat`

## Legal

Solo entretenimiento. Moneda ficticia sin valor real. Mayores de 18 años.
