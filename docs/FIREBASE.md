# Firebase (Oklifor)

## Auth dans l’app Flutter

La connexion par **numéro** passe par l’**API Spring** : `POST /api/v1/auth/otp/request` puis `POST /api/v1/auth/otp/verify` (voir `backend/README.md`).  
En **mode dev** (`OTP_DEV_MODE=true`), tout code à **6 chiffres** est accepté — aucun SMS réel n’est envoyé tant que l’intégration SMS n’est pas branchée côté serveur.

**Firebase Auth (SMS / Google)** n’est plus utilisé dans les écrans login/OTP ; tu peux toutefois garder **Firebase Core** pour les notifications (**FCM**) ou réactiver plus tard un flux natif qui appellerait `POST /api/v1/auth/firebase`.

## Optionnel : échanger un jeton Firebase contre les JWT Oklifor

Si un client obtient un **ID token** Firebase (Phone, Google, etc.) :

1. `POST /api/v1/auth/firebase` avec `{ "idToken": "..." }`.
2. Côté serveur : Firebase Console → **Comptes de service** → clé JSON (Admin SDK).

Variables / config :

```bash
set FIREBASE_ENABLED=true
set GOOGLE_APPLICATION_CREDENTIALS=C:\chemin\vers\serviceAccount.json
```

Ou dans `application.yml` :

```yaml
oklifor:
  firebase:
    enabled: true
    credentials-json-path: C:/chemin/vers/serviceAccount.json
```

Sans `enabled=true` ou sans fichier valide, `POST /api/v1/auth/firebase` répond **503** (`firebase_desactive_cote_serveur`).

## Fichiers natifs (FCM / futurs usages)

1. Projet [Firebase Console](https://console.firebase.google.com).
2. Android : `android/app/google-services.json` (même `package_name` que `applicationId`).
3. iOS : `GoogleService-Info.plist` dans `ios/Runner`.
4. Options Dart : `dart run flutterfire_cli:flutterfire configure` → met à jour `lib/firebase_options.dart`.

## Sécurité

- Ne commite pas la clé JSON du **compte de service**.
- Pour la prod, sers l’API en **HTTPS** et évite le trafic HTTP clair sur les builds release.
