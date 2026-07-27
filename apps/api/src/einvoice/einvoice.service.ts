import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EInvoiceStatus, Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { hasEinvoicePermission } from '../auth/permission-flags';
import { PrismaService } from '../prisma/prisma.service';
import { EInvoiceAdapter, IssueEInvoiceResult } from './einvoice.adapter';
import { EINVOICE_ADAPTER } from './einvoice.tokens';
import { HttpEInvoiceAdapter } from './http-einvoice.adapter';

@Injectable()
export class EInvoiceService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(EINVOICE_ADAPTER) private readonly adapter: EInvoiceAdapter,
    private readonly httpAdapter: HttpEInvoiceAdapter,
  ) {}

  private assertEinvoiceAccess(user: AuthUser) {
    if (!hasEinvoicePermission(user)) {
      throw new ForbiddenException('forbidden');
    }
  }

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('store_forbidden');
    }
  }

  /** P2.4 lifecycle audit — `storeId` is included in `detailJson` (unlike the
   * P1.7 user-management actions) so LedgerService's store-scoped audit
   * filter (`ledgerAuditStoreIds`/`auditStoreIdFragment`, string-matches
   * `"storeId":"<id>"`) also surfaces these rows to a scoped store_manager,
   * not just owner. */
  private async writeEinvoiceAudit(
    tx: Prisma.TransactionClient | PrismaService,
    input: {
      actorUserId: string;
      action: 'einvoice_issue' | 'einvoice_cancel' | 'einvoice_adjust';
      entityId: string;
      storeId: string;
      invoiceNumber: string | null;
      provider: string;
      saleIds: string[];
      reason?: string;
      originalInvoiceId?: string;
      originalInvoiceNumber?: string | null;
    },
  ) {
    await tx.auditLog.create({
      data: {
        id: randomUUID(),
        actorUserId: input.actorUserId,
        action: input.action,
        entityType: 'einvoice',
        entityId: input.entityId,
        detailJson: JSON.stringify({
          storeId: input.storeId,
          invoiceNumber: input.invoiceNumber,
          provider: input.provider,
          saleIds: input.saleIds,
          ...(input.reason !== undefined ? { reason: input.reason } : {}),
          ...(input.originalInvoiceId !== undefined
            ? { originalInvoiceId: input.originalInvoiceId }
            : {}),
          ...(input.originalInvoiceNumber !== undefined
            ? { originalInvoiceNumber: input.originalInvoiceNumber }
            : {}),
        }),
      },
    });
  }

  private normalizeSaleIds(saleIds: string[] | undefined): string[] {
    const normalized = [...new Set((saleIds ?? []).map((id) => id?.trim()))]
      .filter(Boolean);
    if (normalized.length === 0) {
      throw new BadRequestException('saleIds required');
    }
    return normalized;
  }

  private async decorateInvoice<T extends { id: string; saleId: string }>(
    invoice: T,
  ) {
    const links = await this.prisma.eInvoiceSale.findMany({
      where: { invoiceId: invoice.id },
      select: { saleId: true },
      orderBy: { saleId: 'asc' },
    });
    return {
      ...invoice,
      saleIds: links.length ? links.map((l) => l.saleId) : [invoice.saleId],
    };
  }

  private async getLatestInvoiceForSale(saleId: string) {
    return this.prisma.eInvoice.findFirst({
      where: {
        OR: [{ saleId }, { saleLinks: { some: { saleId } } }],
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  private async saleIdsForInvoice(invoice: { id: string; saleId: string }) {
    const links = await this.prisma.eInvoiceSale.findMany({
      where: { invoiceId: invoice.id },
      select: { saleId: true },
    });
    return links.length ? links.map((link) => link.saleId) : [invoice.saleId];
  }

  private mapStatus(result: IssueEInvoiceResult): EInvoiceStatus {
    return result.status === 'issued'
      ? EInvoiceStatus.issued
      : EInvoiceStatus.pending_sign;
  }

  /** Node's `Buffer` types as `Uint8Array<ArrayBufferLike>` while Prisma 6's
   * generated `Bytes` input types are pinned to `Uint8Array<ArrayBuffer>` —
   * cast at the boundary rather than loosening either side. Buffers we build
   * ourselves (pdfkit output, our XML string) are always backed by a real
   * ArrayBuffer, never a SharedArrayBuffer, so this is safe in practice. */
  private toBytes(buf: Buffer | undefined | null): Uint8Array<ArrayBuffer> | null {
    if (!buf) return null;
    return new Uint8Array(buf) as Uint8Array<ArrayBuffer>;
  }

  private isUniqueViolation(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }

  private invoiceLines(
    sales: {
      id: string;
      lines: {
        productId: string;
        product?: { name: string } | null;
        qty: unknown;
        unitPrice: number;
        lineTotal: number;
      }[];
    }[],
  ) {
    return sales.flatMap((sale) =>
      sale.lines.map((l) => ({
        saleId: sale.id,
        productId: l.productId,
        productName: l.product?.name ?? null,
        qty: Number(l.qty),
        unitPrice: l.unitPrice,
        lineTotal: l.lineTotal,
      })),
    );
  }

  private async loadSalesForIssue(
    user: AuthUser,
    saleIds: string[],
    customerId?: string,
  ) {
    const sales = await this.prisma.sale.findMany({
      where: { id: { in: saleIds } },
      include: { lines: { include: { product: true } }, customer: true },
    });
    if (sales.length !== saleIds.length) {
      throw new NotFoundException('sale_not_found');
    }

    const ordered = saleIds.map((id) => sales.find((s) => s.id === id)!);
    const storeId = ordered[0].storeId;
    this.assertStoreAccess(user, storeId);
    if (ordered.some((s) => s.storeId !== storeId)) {
      throw new BadRequestException('einvoice_sales_store_mismatch');
    }
    if (customerId !== undefined) {
      if (!customerId.trim()) {
        throw new BadRequestException('customerId required');
      }
      if (ordered.some((s) => s.customerId !== customerId)) {
        throw new BadRequestException('einvoice_sales_customer_mismatch');
      }
    }

    const activeStatuses = [
      EInvoiceStatus.issued,
      EInvoiceStatus.pending_sign,
      EInvoiceStatus.cancelled,
      EInvoiceStatus.adjusted,
    ];
    const existing = await this.prisma.eInvoice.findFirst({
      where: {
        adjustmentForId: null,
        status: { in: activeStatuses },
        OR: [
          { saleId: { in: saleIds } },
          { saleLinks: { some: { saleId: { in: saleIds } } } },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) {
      const existingSaleIds = await this.saleIdsForInvoice(existing);
      if (
        existing.status === EInvoiceStatus.issued &&
        saleIds.every((saleId) => existingSaleIds.includes(saleId))
      ) {
        return { sales: ordered, existing };
      }
      throw new BadRequestException('einvoice_sale_already_issued');
    }

    return { sales: ordered, existing: null };
  }

  private async persistIssue(
    user: AuthUser,
    saleIds: string[],
    sales: Awaited<ReturnType<EInvoiceService['loadSalesForIssue']>>['sales'],
    body: {
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    const primarySale = sales[0];
    let claim: { id: string };
    try {
      claim = await this.prisma.eInvoice.create({
        data: {
          id: randomUUID(),
          saleId: primarySale.id,
          status: EInvoiceStatus.draft,
          provider: this.adapter.providerName,
          buyerTaxCode: body.buyerTaxCode ?? null,
          templateCode: body.templateCode ?? null,
          serial: body.serial ?? null,
          lastAttemptAt: new Date(),
          retryCount: 0,
          saleLinks: {
            create: saleIds.map((saleId) => ({
              saleId,
              isAdjustment: false,
              claimActive: true,
              claimKey: saleId,
            })),
          },
        },
      });
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw new BadRequestException('einvoice_sale_already_issued');
      }
      throw error;
    }

    let result: IssueEInvoiceResult;
    try {
      result = await this.adapter.issue({
        saleId: primarySale.id,
        saleIds,
        totalVnd: sales.reduce((sum, sale) => sum + sale.totalVnd, 0),
        buyerTaxCode: body.buyerTaxCode,
        buyerName: primarySale.customer?.name ?? null,
        templateCode: body.templateCode,
        serial: body.serial,
        lines: this.invoiceLines(sales),
      });
    } catch (err) {
      await this.prisma.eInvoice.update({
        where: { id: claim.id },
        data: {
          status: EInvoiceStatus.failed,
          errorMessage: String(err).slice(0, 500),
          saleLinks: {
            updateMany: {
              where: {},
              data: { claimActive: false, claimKey: null },
            },
          },
        },
      });
      throw err;
    }

    const status = this.mapStatus(result);
    const invoice = await this.prisma.eInvoice.update({
      where: { id: claim.id },
      data: {
        status,
        invoiceNumber: result.invoiceNumber,
        provider: result.provider,
        providerRef: result.providerRef,
        xmlPath: result.xmlPath ?? null,
        pdfPath: result.pdfPath ?? null,
        xmlContent: this.toBytes(result.xmlContent),
        pdfContent: this.toBytes(result.pdfContent),
        issuedAt: status === EInvoiceStatus.issued ? new Date() : null,
        errorMessage: null,
      },
    });
    await this.writeEinvoiceAudit(this.prisma, {
      actorUserId: user.userId,
      action: 'einvoice_issue',
      entityId: invoice.id,
      storeId: primarySale.storeId,
      invoiceNumber: invoice.invoiceNumber,
      provider: invoice.provider,
      saleIds,
    });
    return this.decorateInvoice(invoice);
  }

  async issue(
    user: AuthUser,
    body: {
      saleId?: string;
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    this.assertEinvoiceAccess(user);
    if (!body.saleId) {
      throw new BadRequestException('saleId required');
    }

    const saleIds = [body.saleId];
    const { sales, existing } = await this.loadSalesForIssue(user, saleIds);
    if (existing) return this.decorateInvoice(existing);
    return this.persistIssue(user, saleIds, sales, body);
  }

  async issueBatch(
    user: AuthUser,
    body: {
      customerId?: string;
      saleIds?: string[];
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    this.assertEinvoiceAccess(user);
    const saleIds = this.normalizeSaleIds(body.saleIds);
    if (!body.customerId) {
      throw new BadRequestException('customerId required');
    }
    const { sales, existing } = await this.loadSalesForIssue(
      user,
      saleIds,
      body.customerId,
    );
    if (existing) return this.decorateInvoice(existing);
    return this.persistIssue(user, saleIds, sales, body);
  }

  async getBySale(user: AuthUser, saleId: string) {
    this.assertEinvoiceAccess(user);
    const sale = await this.prisma.sale.findUnique({
      where: { id: saleId },
    });
    if (!sale) {
      throw new NotFoundException('sale_not_found');
    }
    this.assertStoreAccess(user, sale.storeId);
    const invoice = await this.getLatestInvoiceForSale(saleId);
    return invoice ? this.decorateInvoice(invoice) : null;
  }

  async cancel(
    user: AuthUser,
    id: string,
    body: {
      reason?: string;
    },
  ) {
    this.assertEinvoiceAccess(user);
    const reason = body.reason?.trim();
    if (!reason) {
      throw new BadRequestException('reason required');
    }

    const invoice = await this.prisma.eInvoice.findUnique({
      where: { id },
      include: { sale: true, saleLinks: { include: { sale: true } } },
    });
    if (!invoice) {
      throw new NotFoundException('einvoice_not_found');
    }
    this.assertStoreAccess(user, invoice.sale.storeId);

    if (invoice.status === EInvoiceStatus.cancelled) {
      return this.decorateInvoice(invoice);
    }
    if (
      invoice.status !== EInvoiceStatus.issued &&
      invoice.status !== EInvoiceStatus.pending_sign
    ) {
      throw new BadRequestException('einvoice_cancel_status_invalid');
    }

    await this.adapter.cancel({
      invoiceId: invoice.id,
      providerRef: invoice.providerRef,
      reason,
    });

    const cancelled = await this.prisma.eInvoice.update({
      where: { id: invoice.id },
      data: {
        status: EInvoiceStatus.cancelled,
        lastAttemptAt: new Date(),
        errorMessage: null,
      },
    });
    const cancelledSaleIds = await this.saleIdsForInvoice(cancelled);
    await this.writeEinvoiceAudit(this.prisma, {
      actorUserId: user.userId,
      action: 'einvoice_cancel',
      entityId: cancelled.id,
      storeId: invoice.sale.storeId,
      invoiceNumber: cancelled.invoiceNumber,
      provider: cancelled.provider,
      saleIds: cancelledSaleIds,
      reason,
    });
    return this.decorateInvoice(cancelled);
  }

  async adjust(
    user: AuthUser,
    id: string,
    body: {
      reason?: string;
    },
  ) {
    this.assertEinvoiceAccess(user);
    const reason = body.reason?.trim();
    if (!reason) {
      throw new BadRequestException('reason required');
    }

    const invoice = await this.prisma.eInvoice.findUnique({
      where: { id },
      include: {
        sale: { include: { lines: { include: { product: true } }, customer: true } },
        saleLinks: {
          include: {
            sale: {
              include: { lines: { include: { product: true } }, customer: true },
            },
          },
        },
      },
    });
    if (!invoice) {
      throw new NotFoundException('einvoice_not_found');
    }
    this.assertStoreAccess(user, invoice.sale.storeId);
    if (invoice.adjustmentForId) {
      throw new BadRequestException('einvoice_adjustment_not_adjustable');
    }
    if (invoice.status !== EInvoiceStatus.issued) {
      throw new BadRequestException('einvoice_adjust_status_invalid');
    }

    const linkedSales = invoice.saleLinks.length
      ? invoice.saleLinks.map((link) => link.sale)
      : [invoice.sale];
    const saleIds = linkedSales.map((sale) => sale.id);

    let result: IssueEInvoiceResult;
    try {
      result = await this.adapter.adjust({
        invoiceId: invoice.id,
        providerRef: invoice.providerRef,
        originalInvoiceNumber: invoice.invoiceNumber,
        buyerTaxCode: invoice.buyerTaxCode,
        buyerName: linkedSales[0]?.customer?.name ?? null,
        templateCode: invoice.templateCode,
        serial: invoice.serial,
        saleIds,
        totalVnd: linkedSales.reduce((sum, sale) => sum + sale.totalVnd, 0),
        reason,
        lines: this.invoiceLines(linkedSales),
      });
    } catch (err) {
      await this.prisma.eInvoice.update({
        where: { id: invoice.id },
        data: {
          lastAttemptAt: new Date(),
          retryCount: { increment: 1 },
          errorMessage: String(err).slice(0, 500),
        },
      });
      throw err;
    }

    const status = this.mapStatus(result);
    const adjusted = await this.prisma.$transaction(async (tx) => {
      await tx.eInvoice.update({
        where: { id: invoice.id },
        data: {
          status: EInvoiceStatus.adjusted,
          lastAttemptAt: new Date(),
          errorMessage: null,
        },
      });
      const created = await tx.eInvoice.create({
        data: {
          id: randomUUID(),
          saleId: invoice.saleId,
          status,
          provider: result.provider,
          providerRef: result.providerRef,
          invoiceNumber: result.invoiceNumber,
          xmlPath: result.xmlPath ?? null,
          pdfPath: result.pdfPath ?? null,
          xmlContent: this.toBytes(result.xmlContent),
          pdfContent: this.toBytes(result.pdfContent),
          issuedAt: status === EInvoiceStatus.issued ? new Date() : null,
          adjustmentForId: invoice.id,
          adjustmentReason: reason,
          lastAttemptAt: new Date(),
          retryCount: 0,
          buyerTaxCode: invoice.buyerTaxCode,
          templateCode: invoice.templateCode,
          serial: invoice.serial,
          saleLinks: {
            create: saleIds.map((saleId) => ({
              saleId,
              isAdjustment: true,
              claimActive: false,
              claimKey: null,
            })),
          },
        },
      });
      await this.writeEinvoiceAudit(tx, {
        actorUserId: user.userId,
        action: 'einvoice_adjust',
        entityId: created.id,
        storeId: invoice.sale.storeId,
        invoiceNumber: created.invoiceNumber,
        provider: created.provider,
        saleIds,
        reason,
        originalInvoiceId: invoice.id,
        originalInvoiceNumber: invoice.invoiceNumber,
      });
      return created;
    });
    return this.decorateInvoice(adjusted);
  }

  /**
   * P2.4 download endpoint backing. `kind` picks xml vs pdf.
   * - Stub-issued invoices: DB-stored bytes (xmlContent/pdfContent) served
   *   directly.
   * - Http-provider-issued invoices: xmlPath/pdfPath are real https:// vendor
   *   URLs (validated at issue time by HttpEInvoiceAdapter.parseIssueBody) —
   *   proxy-fetched server-side (auth header, timeout, SSRF re-check) and
   *   streamed back rather than redirecting the client to the raw vendor URL.
   */
  async downloadDocument(
    user: AuthUser,
    id: string,
    kind: 'xml' | 'pdf',
  ): Promise<{ buffer: Buffer; contentType: string; filename: string }> {
    this.assertEinvoiceAccess(user);
    const invoice = await this.prisma.eInvoice.findUnique({
      where: { id },
      include: { sale: true },
    });
    if (!invoice) {
      throw new NotFoundException('einvoice_not_found');
    }
    this.assertStoreAccess(user, invoice.sale.storeId);

    const defaultContentType =
      kind === 'xml' ? 'application/xml' : 'application/pdf';
    // invoiceNumber for http-provider invoices comes from the vendor's HTTP
    // response body (parseIssueBody only checks it's non-empty) — strip it to
    // a safe charset before it lands in the Content-Disposition header, since
    // it's external input by the time it reaches here.
    const safeInvoiceNumber = (invoice.invoiceNumber ?? invoice.id).replace(
      /[^a-zA-Z0-9_-]/g,
      '_',
    );
    const filename = `${safeInvoiceNumber}.${kind}`;
    const content = kind === 'xml' ? invoice.xmlContent : invoice.pdfContent;
    if (content) {
      return {
        buffer: Buffer.from(content),
        contentType: defaultContentType,
        filename,
      };
    }

    const path = kind === 'xml' ? invoice.xmlPath : invoice.pdfPath;
    if (path) {
      const { buffer, contentType } = await this.httpAdapter.fetchDocument(
        path,
        `einvoice ${kind} download`,
      );
      return {
        buffer,
        contentType:
          contentType && contentType !== 'application/octet-stream'
            ? contentType
            : defaultContentType,
        filename,
      };
    }

    throw new NotFoundException(
      kind === 'xml' ? 'einvoice_xml_not_available' : 'einvoice_pdf_not_available',
    );
  }
}
