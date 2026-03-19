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

Variables d’environnement optionnelles : copier `.env.example` vers `.env` si tu ajoutes des clés API (le fichier `.env` est ignoré par Git).

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
dart analyze
flutter test
```

## Structure (aperçu)

| Dossier | Rôle |
|--------|------|
| `lib/core/` | Thème, couleurs, routing, widgets partagés |
| `lib/features/` | Écrans par domaine (chat, discovery, explore, profile, auth…) |

## Licence

Voir le fichier [LICENSE](LICENSE).
