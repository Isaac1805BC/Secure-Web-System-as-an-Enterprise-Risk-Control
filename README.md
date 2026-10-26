# Secure Web System as an Enterprise Risk Control

Workshop — TDSE Tercer Tercio

## Deployed URL

```
https://isaac-risk-lab.duckdns.org
```

## Architecture

```
Browser
  │ login / access token
  ▼
Auth0 ──────────────► React (Vite) ── Bearer token ──► Spring Boot API
                                                     │
Internet ── Duck DNS ── Apache + TLS ────────────────┘
```

## Repository structure

```
.
├── backend/        Spring Boot 4 OAuth2 Resource Server (port 8080)
├── frontend/       Vite + React + @auth0/auth0-react
└── deploy/         systemd unit, Apache vhost, deploy script
```

## Local development

### Backend

```bash
# Copy application.properties and set Auth0 values
cd backend
./mvnw spring-boot:run
# Verify: curl http://localhost:8080/api/risk-status  → 401 Unauthorized
```

### Frontend

```bash
cd frontend
cp .env.local.example .env.local
# Fill in VITE_AUTH0_DOMAIN, VITE_AUTH0_CLIENT_ID
npm run dev
# Open http://localhost:5173
```

## Auth0 configuration

| Variable | Value |
|---|---|
| `VITE_AUTH0_DOMAIN` | `dev-wgnqzydrt31jxn8m.us.auth0.com` |
| `VITE_AUTH0_CLIENT_ID` | SPA client ID (see Auth0 dashboard) |
| `VITE_AUTH0_AUDIENCE` | `https://enterprise-risk-api` |

Auth0 SPA settings require these URLs (both local and production):

- **Allowed Callback URLs**: `http://localhost:5173,https://isaac-risk-lab.duckdns.org`
- **Allowed Logout URLs**: same
- **Allowed Web Origins**: same

The SPA is granted **User-Delegated Access** to the API with the `read:risk`
permission. Client Access alone does not authorize a browser login.

## Deployment

```bash
# Build
cd frontend && npm run build
cd ../backend && ./mvnw clean package

# Copy artifacts to server, then:
cd deploy
bash deploy.sh isaac-risk-lab.duckdns.org \
    ../backend/target/enterprise-risk-api-0.0.1-SNAPSHOT.jar \
    ../frontend/dist
```

## Risk controls

| Control | Risk reduced | Evidence |
|---|---|---|
| Auth0 authentication | Impersonation, weak credentials | Auth0 login flow |
| JWT validation at API | Unauthorized API access | 401 without valid token |
| Audience validation | Token reuse against another API | API accepts only `https://enterprise-risk-api` |
| HTTPS + valid certificate | Token/credential exposure in transit | Browser lock icon |
| Apache reverse proxy | Direct exposure of port 8080 | Only 80/443 public; `server.address=127.0.0.1` |
| systemd journal | Delayed incident investigation | `journalctl -u enterprise-risk-api` |

## Verification checklist

- [ ] Unauthenticated `GET /api/risk-status` returns 401
- [ ] Logged-in user gets 200 with subject and control fields
- [ ] Backend validates JWT issuer and audience
- [ ] Application reachable at `https://isaac-risk-lab.duckdns.org`
- [ ] Browser shows valid certificate (HTTPS lock)
- [ ] Port 8080 not reachable from public internet
- [ ] `sudo certbot renew --dry-run` succeeds
