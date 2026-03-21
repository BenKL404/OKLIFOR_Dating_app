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

## Licence

Voir le fichier [LICENSE](LICENSE).
