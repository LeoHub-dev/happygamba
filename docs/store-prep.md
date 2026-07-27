# App Store / Play Store Prep

## Categoría

- **Google Play**: Juego / Casino simulado (no gambling real)
- **Apple App Store**: Entertainment / Simulation

## Descripción corta

HappyGamba — casino de entretenimiento con moneda ficticia. Slots, blackjack y más. Sin dinero real.

## Keywords

casino, slots, blackjack, entretenimiento, moneda ficticia, simulación

## Screenshots requeridos

1. Lobby con juegos
2. Slots 5x5 en acción
3. Blackjack mesa
4. Tienda de monedas
5. Pantalla VIP

## Checklist legal

- [x] Disclaimer en app (Ajustes)
- [x] Sin retiro de dinero real
- [x] Edad 18+ en descripción
- [ ] Privacy policy URL (requerido para stores)
- [ ] Terms of service URL

## Configuración producción

### Backend
- `JWT_SECRET` — secreto fuerte
- `DATABASE_PATH` — PostgreSQL en prod (migrar desde SQLite)
- `PORT` — 8000 o según hosting

### Flutter
```bash
flutter build apk --dart-define=API_BASE_URL=https://api.happygamba.com
flutter build ios --dart-define=API_BASE_URL=https://api.happygamba.com
```

### AdMob
Reemplazar test ad unit IDs en `lib/services/ads_service.dart` con IDs de producción.

**Importante:** Android requiere `com.google.android.gms.ads.APPLICATION_ID` en
`AndroidManifest.xml` e iOS requiere `GADApplicationIdentifier` en `Info.plist`.
Sin eso, la app puede crashear al arrancar **sin logs de Dart**.

### RevenueCat
Configurar API key real en `lib/services/purchases_service.dart` y productos en dashboard:
- `coins_50k`, `coins_200k`, `coins_1m`
- `happygamba_ad_free`
- `happygamba_vip`

### Firebase (social auth)
Configurar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS).
