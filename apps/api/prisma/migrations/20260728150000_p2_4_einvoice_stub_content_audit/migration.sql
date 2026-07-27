-- P2.4: HĐĐT — lưu PDF/XML thật cho chế độ stub trực tiếp trong DB (không phụ
-- thuộc đĩa cục bộ, an toàn qua redeploy/backup). Provider http tiếp tục dùng
-- xmlPath/pdfPath (URL https:// thật của vendor) — cột dưới đây chỉ dùng khi
-- stub tự sinh nội dung.
ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "xmlContent" BYTEA;
ALTER TABLE "EInvoice" ADD COLUMN IF NOT EXISTS "pdfContent" BYTEA;
