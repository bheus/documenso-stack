#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DOCUMENSO_CERT_PASSWORD:-}" ]; then
  echo "DOCUMENSO_CERT_PASSWORD is required" >&2
  exit 1
fi

BASE_DIR="/home/bheussler/documenso"
SECRETS_DIR="${BASE_DIR}/secrets"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

openssl genrsa -out "${TMPDIR}/private.key" 2048 >/dev/null 2>&1
openssl req -new -x509 \
  -key "${TMPDIR}/private.key" \
  -out "${TMPDIR}/certificate.crt" \
  -days 3650 \
  -subj "/C=US/ST=California/L=San Diego/O=Built by Brendan/OU=Consulting/CN=Built by Brendan Signing/emailAddress=brendan@builtbybrendan.com" \
  >/dev/null 2>&1
openssl pkcs12 -export \
  -out "${SECRETS_DIR}/cert.p12" \
  -inkey "${TMPDIR}/private.key" \
  -in "${TMPDIR}/certificate.crt" \
  -password env:DOCUMENSO_CERT_PASSWORD \
  >/dev/null 2>&1

chmod 400 "${SECRETS_DIR}/cert.p12"

echo "Wrote ${SECRETS_DIR}/cert.p12"
