# Oklifor API (Spring Boot)

Backend REST pour l’app Flutter **Oklifor** : MongoDB, Redis (cache abonnement), JWT.  
**Tous les identifiants métier sont des UUID** (chaînes), jamais des entiers auto-incrémentés.

## Prérequis

- Java **17+**
- Maven **3.9+**
- Docker (recommandé) pour MongoDB + Redis : `docker compose up -d`

## Démarrage

```bash
cd backend
docker compose up -d
mvn spring-boot:run
```

API : `http://localhost:8100` (ou la valeur de `SERVER_PORT`)

Variables utiles :

| Variable | Défaut | Rôle |
|----------|--------|------|
| `MONGODB_URI` | `mongodb://localhost:27017/oklifor` | Base principale |
| `REDIS_HOST` / `REDIS_PORT` | `localhost` / `6379` | Cache + files futures |
| `JWT_SECRET` | (voir `application.yml`) | **≥ 32 caractères** pour HS256 |
| `OTP_DEV_MODE` | `true` | Tout code OTP à 6 chiffres est accepté |
| `FIREBASE_ENABLED` | `false` | `true` + JSON compte de service → vérif. jetons Phone Auth |
| `GOOGLE_APPLICATION_CREDENTIALS` | — | Chemin du JSON compte de service Firebase Admin |
| `MINIO_ENDPOINT` | `http://localhost:9000` | Endpoint objet storage utilisé pour signer les URLs |

### Important — Vrai téléphone Android/iOS (upload média chat)

Pour un téléphone physique, **ne pas** laisser `MINIO_ENDPOINT` à `localhost`.  
Le backend signerait des URLs inaccessibles depuis le téléphone.

Utiliser une IP LAN ou un domaine accessible, par ex. :

- `MINIO_ENDPOINT=http://10.94.43.169:9000`

Vérifier aussi :
- téléphone et machine Docker sur le même réseau,
- port `9000` autorisé (firewall),
- bucket MinIO existant et permissions conformes.

`10.0.2.2` est un alias **émulateur Android uniquement**.

## Auth (démo OTP)

1. `POST /api/v1/auth/otp/request` — `{ "phone": "90123456" }` (+228 ajouté si pas d’indicatif)
2. `POST /api/v1/auth/otp/verify` — `{ "phone": "90123456", "code": "123456" }`  
   → réponse : `accessToken`, `refreshToken`, `userId` (**UUID**)

Ensuite : `Authorization: Bearer <accessToken>`

## Auth Firebase (optionnel)

L’app Flutter utilise en priorité l’**OTP Spring** ci-dessus. Le endpoint suivant reste disponible pour un client qui aurait un jeton Firebase (ex. auth Phone ou Google côté natif) :

`POST /api/v1/auth/firebase` — `{ "idToken": "<Firebase ID token>" }` → mêmes champs JWT que l’OTP.

Nécessite `FIREBASE_ENABLED=true` et un fichier JSON compte de service (`GOOGLE_APPLICATION_CREDENTIALS` ou `oklifor.firebase.credentials-json-path`). Voir `../docs/FIREBASE.md`.

## Endpoints principaux

| Méthode | Chemin | Auth |
|---------|--------|------|
| GET | `/api/v1/subscription-plans` | Non |
| GET | `/api/v1/me` | Oui |
| PATCH | `/api/v1/me/profile` | Oui |
| PATCH | `/api/v1/me/settings` | Oui |
| POST | `/api/v1/me/subscription/activate` | Oui — `{ "planCode": "monthly" \| "yearly", "paymentProvider": "tmoney" }` |
| GET | `/api/v1/chat/threads` | Oui |
| POST | `/api/v1/chat/threads/direct` | Oui — `{ "peerUserId": "<uuid>" }` |
| GET | `/api/v1/chat/threads/{threadId}/messages` | Oui |
| POST | `/api/v1/chat/threads/{threadId}/messages` | Oui |

## Modèle de données (collections Mongo)

- `users` — compte (`phoneE164` unique)
- `profiles` — profil (`userId` unique → UUID utilisateur)
- `user_settings` — réglages (`userId` unique)
- `subscription_plans` — catalogue (seed `monthly` / `yearly` au premier démarrage)
- `user_subscriptions` — souscriptions utilisateur (`planId` = UUID du plan)
- `chat_threads`, `chat_messages` — messagerie

## Prochaines étapes possibles

- WebSocket / STOMP pour le chat temps réel  
- Webhooks Mobile Money + idempotence  
- Refresh token dédié + révocation  
- Stories 24h (TTL Redis + métadonnées Mongo)

## 🚀 CI/CD GitHub Actions (nouveau !)

### Workflows créés :
- `backend-ci-cd.yml` : Maven test → Docker build/push ghcr.io → Deploy VPS
- `flutter-ci.yml` : Flutter test/analyze/build web

### Déploiement automatique :
1. **Push sur `main`** → test → build image `ghcr.io/OWNER/oklifor-api:latest` → **deploy VPS 37.27.222.149**
2. **PR** → tests only

### Configuration requise (GitHub Repo Settings → Secrets) :
```
VPS_SSH_USER          # ex: deploy
VPS_SSH_KEY           # Clé SSH privée VPS (-----BEGIN OPENSSH PRIVATE KEY-----)
JWT_SECRET            # Secret JWT ≥32 chars
MINIO_ROOT_USER       # oklifor
MINIO_ROOT_PASSWORD   # Mot de passe MinIO
```

### Sur VPS (37.27.222.149) :
```
sudo mkdir -p /opt/oklifor  # Ajustez chemin dans workflow
sudo chown $USER:$USER /opt/oklifor
git clone VOTRE_REPO /opt/oklifor
cd /opt/oklifor
# Copier .env depuis .env.example avec vraies valeurs
docker compose -f docker-compose.prod.yml up -d  # Test manuel
```

**Image API :** `ghcr.io/OWNER/oklifor-api:latest` (auto-pull).

**Frontend Flutter web :** Servi par Spring Boot (nginx → api:8100). Build web baked dans JAR.

### Test local workflow :
```bash
# act (outil CLI GitHub Actions local)
brew install act  # macOS
act -j test       # Test backend
```
