# HĐĐT HTTP gateway — operator checklist

Wave 1 go-live: enable the generic HTTP e-invoice adapter when a real provider
gateway is available. No Viettel/MISA SDK in this repo — only env-driven HTTP.

See also:

- Adapter spec: `docs/superpowers/specs/2026-07-25-phase3-einvoice-http-design.md`
- Production env template: `docs/ops/production-deploy.md`
- Secrets handling: `docs/ops/production-secrets.md`

## Step 1 — Trỏ gateway (HTTP provider)

Set these keys in `apps/api/.env.production` on the production host only. Never
commit real URLs, API keys, or `.env.production` to git.

| Env | Required | Meaning |
|-----|----------|---------|
| `EINVOICE_PROVIDER` | Yes | `http` for real gateway; omit or `stub` for non-legal invoices |
| `EINVOICE_HTTP_URL` | When `http` | HTTPS `POST` endpoint that accepts JSON (see spec) |
| `EINVOICE_HTTP_CANCEL_URL` | Optional | Cancel endpoint; defaults to `EINVOICE_HTTP_URL` with `/issue` replaced by `/cancel` |
| `EINVOICE_HTTP_API_KEY` | Optional | Sent as `Authorization: Bearer …` when set |
| `EINVOICE_HTTP_TIMEOUT_MS` | Optional | Request timeout (default `15000`) |
| `EINVOICE_HTTP_MAX_RETRIES` | Optional | Retries on 429/5xx and transport errors (default `2`) |

Example (placeholders only):

```env
EINVOICE_PROVIDER=http
EINVOICE_HTTP_URL=https://gateway.example.com/v1/issue
EINVOICE_HTTP_CANCEL_URL=https://gateway.example.com/v1/cancel
EINVOICE_HTTP_API_KEY=<secret-from-vault>
EINVOICE_HTTP_TIMEOUT_MS=15000
```

After editing env, restart the API container so `EInvoiceModule` picks up the
provider:

```sh
cd apps/api
docker compose -f docker-compose.prod.yml up -d api
```

Startup checks (HTTP mode):

- `EINVOICE_HTTP_URL` must be present; missing URL logs an error at boot.
- Production URL must be `https://` unless `EINVOICE_HTTP_ALLOW_INSECURE=1` or
  host is `localhost` / `127.0.0.1` (dev only).
- Hosts `metadata` and `*.internal` are rejected.

The adapter sends `Idempotency-Key: <saleId>` on every provider call.
Cancel calls send `Idempotency-Key: cancel:<invoiceId>` and body:

```json
{ "invoiceId": "uuid", "providerRef": "ext-id", "reason": "customer request" }
```

## Step 2 — Xuất 1 HĐ thử (Flutter + API verify)

Prerequisites:

1. API running with the intended `EINVOICE_PROVIDER`.
2. POS logged in as **owner** or **store_manager**.
3. At least one sale **synced today** (ICT) for the store.

### Flutter path

1. Open POS → tap **Xuất HĐĐT** (receipt icon on the main POS screen).
2. Select a synced sale from today's list.
3. Optionally fill **MST khách**, **Mẫu số**, **Ký hiệu** (defaults: `1`, `C25TAA`).
4. Tap **Xuất hóa đơn**.
5. Confirm UI shows invoice number, `status`, and `provider` (`http` or `stub`).

If the sale is not on the server yet, the app shows *Đơn chưa có trên server
(chưa sync)* — sync first, then retry.

### API verification (optional curl)

After a successful Flutter issue, or to test without the app:

```sh
# Replace <token> and <saleId> with real values after sync/push
curl -s -X POST "http://<prod-host>:3000/einvoices/issue" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"saleId":"<saleId>","buyerTaxCode":"0123456789","templateCode":"1","serial":"C25TAA"}'
```

Expected when HTTP gateway is healthy:

- HTTP `201`, body `provider` = `http`, `status` = `issued` or `pending_sign`.
- `invoiceNumber`, `providerRef` populated; `xmlPath` / `pdfPath` when returned.

### Allowlist status

The gateway response `status` must be one of: `issued`, `pending_sign`, or
`failed`. Any other value returns `400` with
`einvoice_provider_unknown_status:<value>` and the row is marked failed.

### Idempotency (same sale, second issue)

`EInvoiceService` short-circuits when the sale already has `status=issued` — a
second `POST /einvoices/issue` for the same sale returns the existing row
without calling the provider again.

Operator check:

1. Issue once → note `invoiceNumber`.
2. Issue again for the same sale → same `invoiceNumber`, no duplicate provider
   charge (gateway should also dedupe via `Idempotency-Key` / `saleId`).

## Step 3 — Stub mode (chưa HĐĐT thật)

Use stub when **no legal e-invoice is required on day 1** or no gateway is ready.

```env
# Omit EINVOICE_PROVIDER or explicitly:
EINVOICE_PROVIDER=stub
```

Do **not** set `EINVOICE_HTTP_URL` in stub mode.

Operational meaning:

- Store is **chưa HĐĐT thật** — invoices get synthetic numbers (`STUB-…`).
  Not valid for CQT/tax filing.
- POS **Xuất HĐĐT** still works for workflow testing; UI shows `provider: stub`.
- P2.4: the stub adapter now generates a REAL PDF (readable Vietnamese text)
  and a simple structured XML for every stub issue/adjust, stored as bytes on
  the `EInvoice` row (`xmlContent`/`pdfContent` — DB, not local disk) and
  downloadable via `GET /einvoices/:id/pdf` and `GET /einvoices/:id/xml`. This
  is explicitly NOT the official CQT e-invoice schema (Thông tư 78/Nghị định
  123) — it's a plain export of the same fields the PDF shows, useful for
  handing a buyer *something* printable before a real gateway is connected.
  Provider-hosted invoices (`EINVOICE_PROVIDER=http`) use the same two
  download routes — the API proxy-fetches the vendor's `xmlPath`/`pdfPath`
  (with the same auth header / timeout as issue/cancel/adjust) and streams it
  back, rather than exposing the raw vendor URL to the client.
- Do not train staff to treat stub output as legal tax invoices.

When moving to production HĐĐT:

1. Obtain gateway URL and API key from the provider (outside this repo).
2. Switch env to `EINVOICE_PROVIDER=http` (Step 1).
3. Restart API and run Step 2 on staging before enabling on the live store.

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `EINVOICE_HTTP_URL is required` | `EINVOICE_PROVIDER=http` without URL |
| `einvoice_provider_error:4xx/5xx` | Gateway rejected payload; check provider logs |
| `einvoice_provider_unknown_status` | Gateway returned unsupported `status` |
| `einvoice_provider_unreachable` | Network/timeout after retries |
| `sale_not_found` / 404 on issue | Sale not synced via `POST /sync/push` |
| `store_forbidden` | User not assigned to sale's store |
| `einvoice_xml_not_available` / `einvoice_pdf_not_available` (404 on download) | Invoice has neither stored content nor a provider URL (e.g. a `failed` draft) |
| `einvoice_provider_document_error:4xx/5xx` | Vendor rejected the proxy-fetch of `xmlPath`/`pdfPath` |
| `einvoice_provider_invalid_document_url` (400 on download) | Stored `xmlPath`/`pdfPath` failed the SSRF re-check (non-https outside localhost, or metadata/`*.internal` host) |

Automated coverage: `apps/api/test/einvoice.e2e-spec.ts` (stub — including
P2.4 real PDF/XML download bytes and lifecycle audit visible via
`GET /ledger/audit`), `apps/api/test/einvoice-http.e2e-spec.ts` (HTTP —
including P2.4 proxy-download of vendor content + API key forwarding + audit),
`phase3-hardening.e2e-spec.ts` (idempotency key, unknown status).
