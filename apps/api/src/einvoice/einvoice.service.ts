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
import { EInvoiceAdapter } from './einvoice.adapter';
import { EINVOICE_ADAPTER } from './einvoice.tokens';

@Injectable()
export class EInvoiceService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(EINVOICE_ADAPTER) private readonly adapter: EInvoiceAdapter,
  ) {}

  async issue(
    user: AuthUser,
    body: {
      saleId?: string;
      buyerTaxCode?: string;
      templateCode?: string;
      serial?: string;
    },
  ) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!body.saleId) {
      throw new BadRequestException('saleId required');
    }

    const sale = await this.prisma.sale.findUnique({
      where: { id: body.saleId },
      include: { eInvoice: true, lines: true },
    });
    if (!sale) {
      throw new NotFoundException('sale_not_found');
    }
    if (
      user.role !== Role.owner &&
      !user.storeIds.includes(sale.storeId)
    ) {
      throw new ForbiddenException('store_forbidden');
    }

    if (sale.eInvoice?.status === EInvoiceStatus.issued) {
      return sale.eInvoice;
    }
    if (sale.eInvoice?.status === EInvoiceStatus.cancelled) {
      throw new BadRequestException('einvoice_cancelled');
    }

    // Claim attempt row to reduce concurrent provider calls for same sale
    let claim = sale.eInvoice;
    if (!claim) {
      claim = await this.prisma.eInvoice.create({
        data: {
          id: randomUUID(),
          saleId: sale.id,
          status: EInvoiceStatus.draft,
          provider: this.adapter.providerName,
          buyerTaxCode: body.buyerTaxCode ?? null,
          templateCode: body.templateCode ?? null,
          serial: body.serial ?? null,
          lastAttemptAt: new Date(),
          retryCount: 0,
        },
      });
    } else {
      claim = await this.prisma.eInvoice.update({
        where: { id: claim.id },
        data: {
          lastAttemptAt: new Date(),
          retryCount: { increment: 1 },
          buyerTaxCode: body.buyerTaxCode ?? claim.buyerTaxCode,
          templateCode: body.templateCode ?? claim.templateCode,
          serial: body.serial ?? claim.serial,
        },
      });
    }

    let result;
    try {
      result = await this.adapter.issue({
        saleId: sale.id,
        totalVnd: sale.totalVnd,
        buyerTaxCode: body.buyerTaxCode,
        templateCode: body.templateCode,
        serial: body.serial,
        lines: sale.lines.map((l) => ({
          productId: l.productId,
          qty: Number(l.qty),
          unitPrice: l.unitPrice,
          lineTotal: l.lineTotal,
        })),
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

    const status =
      result.status === 'issued'
        ? EInvoiceStatus.issued
        : EInvoiceStatus.pending_sign;

    return this.prisma.eInvoice.update({
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
  }

  async getBySale(user: AuthUser, saleId: string) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const sale = await this.prisma.sale.findUnique({
      where: { id: saleId },
      include: { eInvoice: true },
    });
    if (!sale) {
      throw new NotFoundException('sale_not_found');
    }
    if (
      user.role !== Role.owner &&
      !user.storeIds.includes(sale.storeId)
    ) {
      throw new ForbiddenException('store_forbidden');
    }
    return sale.eInvoice;
  }

  async cancel(
    user: AuthUser,
    id: string,
    body: {
      reason?: string;
    },
  ) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const reason = body.reason?.trim();
    if (!reason) {
      throw new BadRequestException('reason required');
    }

    const invoice = await this.prisma.eInvoice.findUnique({
      where: { id },
      include: { sale: true },
    });
    if (!invoice) {
      throw new NotFoundException('einvoice_not_found');
    }
    if (
      user.role !== Role.owner &&
      !user.storeIds.includes(invoice.sale.storeId)
    ) {
      throw new ForbiddenException('store_forbidden');
    }

    if (invoice.status === EInvoiceStatus.cancelled) {
      return invoice;
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

    return this.prisma.eInvoice.update({
      where: { id: invoice.id },
      data: {
        status: EInvoiceStatus.cancelled,
        lastAttemptAt: new Date(),
        errorMessage: null,
      },
    });
  }
}
