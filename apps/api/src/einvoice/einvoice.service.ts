import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EInvoiceStatus, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import { EInvoiceAdapter, IssueEInvoiceResult } from './einvoice.adapter';
import { EINVOICE_ADAPTER } from './einvoice.tokens';

@Injectable()
export class EInvoiceService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(EINVOICE_ADAPTER) private readonly adapter: EInvoiceAdapter,
  ) {}

  private assertManager(user: AuthUser) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
  }

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new ForbiddenException('store_forbidden');
    }
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

  private mapStatus(result: IssueEInvoiceResult): EInvoiceStatus {
    return result.status === 'issued'
      ? EInvoiceStatus.issued
      : EInvoiceStatus.pending_sign;
  }

  private invoiceLines(
    sales: {
      id: string;
      lines: {
        productId: string;
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
      include: { lines: true },
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
      if (saleIds.length === 1 && existing.status === EInvoiceStatus.issued) {
        return { sales: ordered, existing };
      }
      throw new BadRequestException('einvoice_sale_already_issued');
    }

    return { sales: ordered, existing: null };
  }

  private async persistIssue(
    saleIds: string[],
    sales: Awaited<ReturnType<EInvoiceService['loadSalesForIssue']>>['sales'],
    body: {
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    const primarySale = sales[0];
    const claim = await this.prisma.eInvoice.create({
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
          create: saleIds.map((saleId) => ({ saleId })),
        },
      },
    });

    let result: IssueEInvoiceResult;
    try {
      result = await this.adapter.issue({
        saleId: primarySale.id,
        saleIds,
        totalVnd: sales.reduce((sum, sale) => sum + sale.totalVnd, 0),
        buyerTaxCode: body.buyerTaxCode,
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
        issuedAt: status === EInvoiceStatus.issued ? new Date() : null,
        errorMessage: null,
      },
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
    this.assertManager(user);
    if (!body.saleId) {
      throw new BadRequestException('saleId required');
    }

    const saleIds = [body.saleId];
    const { sales, existing } = await this.loadSalesForIssue(user, saleIds);
    if (existing) return this.decorateInvoice(existing);
    return this.persistIssue(saleIds, sales, body);
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
    this.assertManager(user);
    const saleIds = this.normalizeSaleIds(body.saleIds);
    if (!body.customerId) {
      throw new BadRequestException('customerId required');
    }
    const { sales } = await this.loadSalesForIssue(
      user,
      saleIds,
      body.customerId,
    );
    return this.persistIssue(saleIds, sales, body);
  }

  async getBySale(user: AuthUser, saleId: string) {
    this.assertManager(user);
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
    this.assertManager(user);
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
    return this.decorateInvoice(cancelled);
  }

  async adjust(
    user: AuthUser,
    id: string,
    body: {
      reason?: string;
    },
  ) {
    this.assertManager(user);
    const reason = body.reason?.trim();
    if (!reason) {
      throw new BadRequestException('reason required');
    }

    const invoice = await this.prisma.eInvoice.findUnique({
      where: { id },
      include: {
        sale: { include: { lines: true } },
        saleLinks: { include: { sale: { include: { lines: true } } } },
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
      return tx.eInvoice.create({
        data: {
          id: randomUUID(),
          saleId: invoice.saleId,
          status,
          provider: result.provider,
          providerRef: result.providerRef,
          invoiceNumber: result.invoiceNumber,
          xmlPath: result.xmlPath ?? null,
          pdfPath: result.pdfPath ?? null,
          issuedAt: status === EInvoiceStatus.issued ? new Date() : null,
          adjustmentForId: invoice.id,
          adjustmentReason: reason,
          lastAttemptAt: new Date(),
          retryCount: 0,
          buyerTaxCode: invoice.buyerTaxCode,
          templateCode: invoice.templateCode,
          serial: invoice.serial,
          saleLinks: {
            create: saleIds.map((saleId) => ({ saleId })),
          },
        },
      });
    });
    return this.decorateInvoice(adjusted);
  }
}
