# Documenso Stack

Documenso stack for `apple-pi.lan`, deployed through Portainer from Git.

## Model

- Git is the source of truth.
- Portainer deploys the stack from this repo.
- Secrets do not live in Git.
- Persistent state uses absolute host paths on `apple-pi`.

## Host paths on apple-pi

Create these on the host before first deploy:

```bash
mkdir -p /home/bheussler/documenso/data/postgres
mkdir -p /home/bheussler/documenso/secrets
chmod 700 /home/bheussler/documenso/secrets
```

Expected files:

- Postgres data: `/home/bheussler/documenso/data/postgres`
- Signing cert: `/home/bheussler/documenso/secrets/cert.p12`

## Generate app secrets

Use these on `apple-pi` and paste the values into Portainer's environment UI:

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

Run [`scripts/create-signing-cert.sh`](scripts/create-signing-cert.sh) on `apple-pi` after setting `DOCUMENSO_CERT_PASSWORD` in the shell.

Example:

```bash
export DOCUMENSO_CERT_PASSWORD='your-p12-password'
./scripts/create-signing-cert.sh
```

The script writes:

- `/home/bheussler/documenso/secrets/cert.p12`

## Portainer deployment

1. Push this repo to GitHub.
2. In Portainer, create a new stack from Git.
3. Point it at this repo and branch.
4. Use `docker-compose.yml` at the repo root.
5. In the Portainer env UI, add the variables from `.env.example`.

Important:

- This compose intentionally uses `env_file: ./stack.env` behavior via Portainer's repo-root env handling.
- Keep the compose file at the repo root so Portainer's generated `stack.env` resolves cleanly.
- Use absolute host paths for bind mounts. Do not switch these to relative paths.

## First boot

- Leave `NEXT_PUBLIC_DISABLE_SIGNUP=false` for the first deploy so you can create the first account.
- After the first account exists, set `NEXT_PUBLIC_DISABLE_SIGNUP=true` in Portainer and redeploy.

## Exposure

After local validation on `http://apple-pi.lan:3020`, add this to `/etc/cloudflared/config.yml` on `apple-pi`:

```yaml
- hostname: contracts.builtbybrendan.com
  service: http://localhost:3020
```

Then apply it with:

```bash
docker restart cloudflared-tunnel
```

## Backup boundary

Back up:

- PostgreSQL database
- `/home/bheussler/documenso/secrets/cert.p12`
- Portainer-managed env values or an exported copy of `stack.env`

## Notes

- Documenso requires PostgreSQL, not MySQL.
- Database-backed uploads are simplest to start with and keep the stack small.
- Once the deployment is stable, pin the Documenso image to a tested tag instead of `latest`.
