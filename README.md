# Keychain Shop — Final Year Project

Flutter + Firebase e-commerce & home-to-home delivery system for custom keychains.

## Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter, Dart, Material 3 |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Files | Firebase Storage |
| Server logic | Firebase Cloud Functions |
| Push | Firebase Cloud Messaging |

**No custom Node/Express/Mongo/MySQL/PHP backend.**

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Project setup, Firebase wiring, models, auth service, theme, rules | Done |
| 2 | Splash, onboarding, login/signup, forgot password, customer home | Done |
| 3 | Categories, products, details, search, filters, favorites | Done |
| 4 | Cart, checkout, addresses, COD, online payment architecture | Done |
| 5 | Orders, tracking, notifications, home-to-home delivery | Done |
| 6 | Admin auth, dashboard, product/category/customer management | Done |
| 7 | Admin orders, delivery, reviews, coupons, reports | Done |
| 8 | Testing, rules hardening, polish, release build | **Done** |

## Packages (why they were added)

| Package | Why | Where used |
|---------|-----|------------|
| `firebase_core` | Initialize Firebase | `main.dart` |
| `firebase_auth` | Email/password auth, reset, session | `AuthService` |
| `cloud_firestore` | Primary database | models + `FirestoreService` |
| `firebase_storage` | Product/profile/custom images | `StorageService` |
| `firebase_messaging` | Push notifications | `NotificationService` |
| `cloud_functions` | Secure server logic | coupons, order status, payments |
| `provider` | App-wide state | Auth / cart / orders providers |
| `go_router` | Scalable navigation | Customer + admin routes |
| `google_fonts` | Brand typography (Outfit + Plus Jakarta) | `AppTheme` |
| `shared_preferences` | Onboarding / local flags | Splash / onboarding |
| `image_picker` | Profile & product photos | Admin + custom keychains |
| `cached_network_image` | Cached product images | Catalog UI |
| `intl` | Currency/date formatting | `Formatters` |
| `flutter_svg` | Vector icons/assets | UI assets |

## Firebase setup

See `docs/FIREBASE_SETUP.md` and `docs/FIRESTORE_STRUCTURE.md`.

Quick deploy:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## Run

```bash
flutter pub get
flutter run
```

## Test & release

```bash
flutter analyze lib
flutter test
flutter build apk --release
```

Full checklist: `docs/RELEASE.md`. Phase notes: `docs/PHASE_1.md` … `docs/PHASE_8.md`.
