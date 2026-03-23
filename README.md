# Oklifor — application de rencontre (Flutter)

Application mobile **Flutter** (Découverte, chat, profil, exploration de lieux). UI sombre, navigation avec **Go Router**, état avec **Riverpod**.

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK compatible `pubspec.yaml`, actuellement **Dart ^3.10**)
- Un éditeur (VS Code, Android Studio) avec extensions Flutter/Dart

## Installation

```bash
git clone <URL_DU_DEPOT_GITHUB>
cd oklifor_dating_app
flutter pub get
```

**Configuration** : l’app charge **`assets/.env`** au démarrage (`OKLIFOR_API_BASE`, etc.). Voir **`.env.example`** à la racine pour la liste des variables (Flutter + rappels backend). Priorité : `--dart-define=OKLIFOR_API_BASE=...` > `assets/.env` > défaut (port **8100** par défaut côté `application.yml`). Un `.env` à la racine n’est **pas** lu par Flutter par défaut — modifie plutôt `assets/.env`.

### API Spring Boot (Flutter)

L’app appelle le backend dans [`backend/`](backend/README.md) via **Dio** :

- URL par défaut : **Android émulateur** → `http://10.0.2.2:8100`, **iOS / desktop / web** → `http://127.0.0.1:8100`.
- **Téléphone Android réel** : `10.0.2.2` **ne fonctionne pas**. Dans **`assets/.env`**, définis `OKLIFOR_API_BASE` :
  - **Wi‑Fi** : `http://<IPv4_du_PC_sur_le_même_Wi‑Fi>:8100` (voir `ipconfig` sur Windows).
  - **USB** : `adb reverse tcp:8100 tcp:8100` puis `OKLIFOR_API_BASE=http://127.0.0.1:8100`.
  Ouvre le **pare-feu** Windows sur le port **8100** si tu es en Wi‑Fi.
- Surcharge : `flutter run --dart-define=OKLIFOR_API_BASE=http://TON_IP:8100` ou édite `assets/.env`.

Flux : splash → jeton stocké → `GET /api/v1/me` ; login → **OTP Spring** (`POST /api/v1/auth/otp/*`) ; après auth → `GET /me` ; profil + VIP dans `ProfileSession` / `VipSession`. À l’entrée dans l’app principale (`MainShell`), **`/me` est rappelé** pour resynchroniser profil / abonnement. L’onglet **Messages** charge les fils via **`GET /api/v1/chat/threads`** (remplace les démos si l’API répond) ; une conversation dont l’id est un **UUID** charge et envoie les messages via l’API. Déconnexion : stockage jetons + `/login`.

Avec `OTP_DEV_MODE=true` (défaut), **n’importe quel code à 6 chiffres** est accepté tant que le numéro est valide — pratique sans SMS réel. Firebase reste initialisé pour **FCM** / options futures ; l’auth téléphone par Firebase n’est plus utilisée dans l’app. Voir [docs/FIREBASE.md](docs/FIREBASE.md) pour FCM ou une intégration optionnelle `POST /auth/firebase`.

## Lancer le projet

```bash
flutter run
```

Cible explicite :

```bash
flutter run -d chrome    # Web
flutter run -d windows   # Windows
```

## Qualité du code

```bash
flutter analyze
flutter test
```

## CI (GitHub Actions)

Sur chaque push ou pull request vers `main`, `master` ou `develop`, le workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) exécute :

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

Après avoir poussé le dépôt sur GitHub, consulte l’onglet **Actions** du repo pour voir les résultats. Tu peux ajouter une protection de branche (**Settings → Branches → Branch protection rules**) pour exiger que ce workflow soit vert avant merge.

## Structure (aperçu)

| Dossier | Rôle |
|--------|------|
| `lib/core/` | Thème, couleurs, routing, widgets partagés |
| `lib/features/` | Écrans par domaine (chat, discovery, explore, profile, auth…) |
| [`backend/`](backend/README.md) | API Spring Boot (MongoDB, Redis, JWT) — **IDs UUID** |

## Licence

Voir le fichier [LICENSE](LICENSE).
