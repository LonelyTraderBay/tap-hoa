# Phase 3 — HĐĐT HTTP adapter (1 provider)

## Goal

Replace always-on stub with env-selected **HTTP** adapter that POSTs sale payload to a provider gateway URL. Local/e2e default remains `stub`.

## Config

| Env | Meaning |
|-----|---------|
| `EINVOICE_PROVIDER` | `stub` (default) or `http` |
| `EINVOICE_HTTP_URL` | Required when provider=`http` — `POST` JSON endpoint |
| `EINVOICE_HTTP_API_KEY` | Optional `Authorization: Bearer …` |

## Request body (tap-hoa → provider)

```json
{
  "saleId": "uuid",
  "totalVnd": 110000,
  "buyerTaxCode": "0100…",
  "templateCode": "1",
  "serial": "C25TAA",
  "lines": [{ "productId": "…", "qty": 1, "unitPrice": 110000, "lineTotal": 110000 }]
}
```

## Expected provider response

```json
{
  "providerRef": "ext-id",
  "invoiceNumber": "INV-…",
  "status": "issued" | "pending_sign",
  "xmlPath": "https://…",
  "pdfPath": "https://…"
}
```

## Idempotency

`EInvoiceService` already short-circuits when sale has `status=issued`. HTTP adapter should send `saleId` so the gateway can dedupe.

## Out of scope

Viettel/MISA SDK specifics; CQT filing; async webhook poll beyond `pending_sign` storage.
