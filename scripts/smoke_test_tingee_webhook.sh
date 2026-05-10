#!/usr/bin/env bash
# Smoke test for the deployed tingee-webhook Edge Function.
#
# Sends a fake Tingee notification with a correctly computed HMAC-SHA512
# signature. Expects code "00" (or "02" if previously seeded) in the
# response. Verifies signature gating, payload parsing, and the
# linked_bank_accounts lookup.
#
# Usage:
#   TINGEE_SECRET_TOKEN=... ./scripts/smoke_test_tingee_webhook.sh
# Or:
#   ./scripts/smoke_test_tingee_webhook.sh
#     (it will read .env if present)
#
# Requirements: bash, curl, openssl

set -euo pipefail

if [[ -z "${TINGEE_SECRET_TOKEN:-}" && -f .env ]]; then
  TINGEE_SECRET_TOKEN=$(grep -E '^TINGEE_SECRET_TOKEN=' .env | cut -d= -f2- | tr -d '"' || true)
fi

if [[ -z "${TINGEE_SECRET_TOKEN:-}" ]]; then
  echo "TINGEE_SECRET_TOKEN not set. Export it or put it in .env."
  echo "(Or run: read -s -p 'TINGEE_SECRET_TOKEN: ' TINGEE_SECRET_TOKEN; export TINGEE_SECRET_TOKEN)"
  exit 1
fi

WEBHOOK_URL="${WEBHOOK_URL:-https://gulptwduchsjcsbndmua.supabase.co/functions/v1/tingee-webhook}"
TINGEE_CLIENT_ID="${TINGEE_CLIENT_ID:-30d65b07f2cf19a5b47fe0b1f4f27075}"

# Build a fake payload. transactionCode includes timestamp so each run is
# unique (idempotency: same code returns "02" the second time).
TS=$(date +%s)
TX_CODE="smoke-$(date +%s%N)"
TX_DATE=$(date +%Y%m%d%H%M%S)
PAYLOAD="{\"clientId\":\"$TINGEE_CLIENT_ID\",\"transactionCode\":\"$TX_CODE\",\"amount\":50000,\"content\":\"Smoke test from Bexly CI\",\"bank\":\"VCB\",\"accountNumber\":\"*****1234\",\"vaAccountNumber\":\"9999000001\",\"transactionDate\":\"$TX_DATE\",\"additionalData\":[]}"

# HMAC-SHA512(timestamp + ':' + body, secret), hex-encoded
SIGNED_PAYLOAD="${TS}:${PAYLOAD}"
SIG=$(printf '%s' "$SIGNED_PAYLOAD" |
  openssl dgst -sha512 -hmac "$TINGEE_SECRET_TOKEN" |
  awk '{print $2}')

echo "── Smoke test ────────────────────────────────────────────"
echo "URL:        $WEBHOOK_URL"
echo "Timestamp:  $TS"
echo "TX code:    $TX_CODE"
echo "Payload:    $PAYLOAD"
echo "Signature:  $SIG"
echo "──────────────────────────────────────────────────────────"

RESPONSE=$(curl -sS -w '\nHTTP_STATUS:%{http_code}' -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "x-client-id: $TINGEE_CLIENT_ID" \
  -H "x-request-timestamp: $TS" \
  -H "x-signature: $SIG" \
  -d "$PAYLOAD")

STATUS=$(echo "$RESPONSE" | tail -n1 | sed 's/HTTP_STATUS://')
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP $STATUS"
echo "Body: $BODY"
echo

CODE=$(echo "$BODY" | sed -n 's/.*"code"\s*:\s*"\([^"]*\)".*/\1/p')
[[ -z "$CODE" ]] && CODE='?'
case "$CODE" in
  00) echo "✅ OK — webhook accepted (no linked account → silent ack)";;
  02) echo "✅ DUPLICATE — already seen, idempotent path works";;
  *)  echo "❌ Unexpected code: $CODE"; exit 1;;
esac
