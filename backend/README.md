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
