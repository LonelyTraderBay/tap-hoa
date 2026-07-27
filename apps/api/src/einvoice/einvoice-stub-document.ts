import { existsSync } from 'fs';
import { join } from 'path';
import PDFDocument from 'pdfkit';

/**
 * P2.4 — real, downloadable output for the STUB e-invoice provider (used
 * whenever EINVOICE_PROVIDER is unset/not 'http', i.e. no paid HĐĐT gateway
 * configured yet). This is a plain structured export of the same fields the
 * PDF shows — explicitly NOT the official tax-authority e-invoice XML schema
 * (Thông tư 78 / Nghị định 123). Out of scope per spec §5.6; do not extend
 * this toward CQT-format compliance.
 */

const STUB_PDF_FONT_NAME = 'NotoSans';
const STUB_PDF_FONT_FILE = 'NotoSans-Regular.ttf';

export type StubInvoiceLine = {
  productId: string;
  productName?: string | null;
  qty: number;
  unitPrice: number;
  lineTotal: number;
};

export type StubInvoiceData = {
  invoiceNumber: string;
  issuedAt: Date;
  templateCode?: string | null;
  serial?: string | null;
  buyerName?: string | null;
  buyerTaxCode?: string | null;
  totalVnd: number;
  lines: StubInvoiceLine[];
};

function resolveStubPdfFontPath(): string | null {
  const candidates = [
    join(process.cwd(), 'assets', 'fonts', STUB_PDF_FONT_FILE),
    join(__dirname, '..', '..', 'assets', 'fonts', STUB_PDF_FONT_FILE),
    join(__dirname, '..', '..', '..', 'assets', 'fonts', STUB_PDF_FONT_FILE),
  ];
  return candidates.find((candidate) => existsSync(candidate)) ?? null;
}

function formatVnd(n: number): string {
  return new Intl.NumberFormat('vi-VN').format(n) + ' đ';
}

function xmlEscape(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/** Simple self-describing XML export — not a CQT-format e-invoice. */
export function buildStubInvoiceXml(data: StubInvoiceData): Buffer {
  const lines = data.lines
    .map(
      (l) => `    <Line>
      <ProductId>${xmlEscape(l.productId)}</ProductId>
      <ProductName>${xmlEscape(l.productName ?? '')}</ProductName>
      <Qty>${l.qty}</Qty>
      <UnitPrice>${l.unitPrice}</UnitPrice>
      <LineTotal>${l.lineTotal}</LineTotal>
    </Line>`,
    )
    .join('\n');
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<Invoice>
  <Number>${xmlEscape(data.invoiceNumber)}</Number>
  <IssuedAt>${data.issuedAt.toISOString()}</IssuedAt>
  <TemplateCode>${xmlEscape(data.templateCode ?? '')}</TemplateCode>
  <Serial>${xmlEscape(data.serial ?? '')}</Serial>
  <Buyer>
    <Name>${xmlEscape(data.buyerName ?? '')}</Name>
    <TaxCode>${xmlEscape(data.buyerTaxCode ?? '')}</TaxCode>
  </Buyer>
  <Lines>
${lines}
  </Lines>
  <TotalVnd>${data.totalVnd}</TotalVnd>
</Invoice>
`;
  return Buffer.from(xml, 'utf8');
}

export function buildStubInvoicePdf(data: StubInvoiceData): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(Buffer.from(c)));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const fontPath = resolveStubPdfFontPath();
    if (fontPath) {
      doc.registerFont(STUB_PDF_FONT_NAME, fontPath);
      doc.font(STUB_PDF_FONT_NAME);
    } else {
      doc.font('Helvetica');
    }

    doc.fontSize(16).text('HÓA ĐƠN (chế độ stub)', { underline: true });
    doc.fontSize(10);
    doc.moveDown(0.5);
    doc.text(`Số: ${data.invoiceNumber}`);
    if (data.templateCode) doc.text(`Mẫu số: ${data.templateCode}`);
    if (data.serial) doc.text(`Ký hiệu: ${data.serial}`);
    doc.text(`Ngày: ${data.issuedAt.toISOString()}`);
    doc.moveDown();
    doc.text(`Người mua: ${data.buyerName?.trim() || '(khách lẻ)'}`);
    if (data.buyerTaxCode) doc.text(`Mã số thuế: ${data.buyerTaxCode}`);
    doc.moveDown();
    doc.fontSize(11).text('Chi tiết hàng hóa', { underline: true });
    doc.fontSize(10);
    for (const l of data.lines) {
      if (doc.y > 700) doc.addPage();
      doc.text(
        `${l.productName?.trim() || l.productId} — SL ${l.qty} x ${formatVnd(
          l.unitPrice,
        )} = ${formatVnd(l.lineTotal)}`,
      );
    }
    doc.moveDown();
    if (doc.y > 700) doc.addPage();
    doc.fontSize(12).text(`Tổng cộng: ${formatVnd(data.totalVnd)}`, {
      underline: true,
    });
    doc.moveDown();
    doc.fontSize(8).text(
      'Chứng từ nội bộ (chế độ stub) — không phải hóa đơn điện tử hợp lệ ' +
        'theo Nghị định 123/2020/NĐ-CP và Thông tư 78/2021/TT-BTC. Chỉ dùng ' +
        'khi cửa hàng chưa đấu nối nhà cung cấp HĐĐT thật.',
    );
    doc.end();
  });
}
