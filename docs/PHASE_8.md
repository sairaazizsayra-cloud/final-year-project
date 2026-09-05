# Phase 8 Completion Report

## Completed

### Security hardening
- Stricter Firestore rules for cart (active users), orders create payload, rider delivery field limits
- Reviews must start with `isApproved: false`; customers cannot self-approve
- Deactivated users cannot mutate cart/addresses
- Enhanced `validateCoupon` Cloud Function (dates, min order, usage limit, max discount)

### Polish
- Checkout coupon apply/remove via Cloud Function
- Customer review submission on delivered orders (pending admin approval)
- Profile: Help, About, Admin panel shortcut
- Android app label **Keychain Shop** + `INTERNET` / `POST_NOTIFICATIONS`

### Testing
- Unit tests: formatters, validators, product/coupon/order models
- Widget smoke test (theme + brand name)
- Broken counter `widget_test` replaced

### Release
- See `docs/RELEASE.md` for APK/App Bundle build steps
- README + Firebase setup docs refreshed for current state

## Verify locally

```bash
flutter analyze lib
flutter test
```

Deploy rules / functions / indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## Project complete (phases 1–8)

| Phase | Status |
|-------|--------|
| 1–7 | Done (see prior PHASE_*.md) |
| 8 | **Done** |

Optional follow-ups (out of core FYP scope): rider mobile UI, production payment gateway keys, Play Store signing keystore.
