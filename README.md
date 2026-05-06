# Documenso Stack

Documenso stack deployed through Portainer from Git.

## Model

- Git is the source of truth.
- Portainer deploys the stack from this repo.
- Secrets do not live in Git.
- Postgres state lives in a Docker named volume.
- The signing certificate stays as a host file outside Git.

## Host Paths

Create this on the host before first deploy:

```bash
mkdir -p /srv/documenso/secrets
chmod 700 /srv/documenso/secrets
```

Expected file:

- Signing cert: `/srv/documenso/secrets/cert.p12`

## Generate app secrets

Generate these on the Docker host and paste the values into Portainer's environment UI:

```bash
openssl rand -hex 24
openssl rand -hex 32
openssl rand -hex 32
openssl rand -hex 32
openssl rand -hex 24
```

Map them like this:

- 24 hex: `POSTGRES_PASSWORD`
- 32 hex: `NEXTAUTH_SECRET`
- 32 hex: `NEXT_PRIVATE_ENCRYPTION_KEY`
- 32 hex: `NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY`
- 24 hex: `NEXT_PRIVATE_SIGNING_PASSPHRASE`

## Generate signing certificate

Run [`scripts/create-signing-cert.sh`](scripts/create-signing-cert.sh) on the Docker host after setting `DOCUMENSO_CERT_PASSWORD` in the shell.

Example:

```bash
export DOCUMENSO_CERT_PASSWORD='your-p12-password'
export DOCUMENSO_BASE_DIR='/srv/documenso'
export DOCUMENSO_CERT_SUBJECT='/C=US/ST=State/L=City/O=Organization/OU=Signing/CN=Documenso Signing/emailAddress=admin@example.com'
./scripts/create-signing-cert.sh
```

The script writes:

- `${DOCUMENSO_BASE_DIR}/secrets/cert.p12`

## Portainer deployment

1. Push this repo to GitHub.
2. In Portainer, create a new stack from Git.
3. Point it at this repo and branch.
4. Use `docker-compose.yml` at the repo root.
5. In the Portainer env UI, add the variables from `.env.example`.

Important:

- This compose intentionally uses `env_file: ./stack.env` behavior via Portainer's repo-root env handling.
- Keep the compose file at the repo root so Portainer's generated `stack.env` resolves cleanly.
- Only the certificate uses a host bind mount. Set `DOCUMENSO_CERT_HOST_PATH` in Portainer to the absolute host path.

## First boot

- Leave `NEXT_PUBLIC_DISABLE_SIGNUP=false` for the first deploy so you can create the first account.
- After the first account exists, set `NEXT_PUBLIC_DISABLE_SIGNUP=true` in Portainer and redeploy.

## Exposure

After local validation, publish the service through your reverse proxy or tunnel. Example Cloudflare Tunnel ingress:

```yaml
- hostname: sign.example.com
  service: http://localhost:3020
```

Then reload or restart your tunnel/reverse-proxy service.

Keep `NEXT_PUBLIC_WEBAPP_URL` set to the public URL users will open.

## Backup boundary

Back up:

- PostgreSQL named volume `documenso_postgres_data`
- The certificate file referenced by `DOCUMENSO_CERT_HOST_PATH`
- Portainer-managed env values or an exported copy of `stack.env`

## Notes

- Documenso requires PostgreSQL, not MySQL.
- Database-backed uploads are simplest to start with and keep the stack small.
- Keep the Documenso image pinned to a tested tag and update deliberately.
