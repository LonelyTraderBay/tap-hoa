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

    const result = await this.adapter.issue({
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

    const status =
      result.status === 'issued'
        ? EInvoiceStatus.issued
        : EInvoiceStatus.pending_sign;

    if (sale.eInvoice) {
      return this.prisma.eInvoice.update({
        where: { id: sale.eInvoice.id },
        data: {
          status,
          buyerTaxCode: body.buyerTaxCode ?? sale.eInvoice.buyerTaxCode,
          templateCode: body.templateCode ?? sale.eInvoice.templateCode,
          serial: body.serial ?? sale.eInvoice.serial,
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

    return this.prisma.eInvoice.create({
      data: {
        id: randomUUID(),
        saleId: sale.id,
        status,
        buyerTaxCode: body.buyerTaxCode ?? null,
        templateCode: body.templateCode ?? null,
        serial: body.serial ?? null,
        invoiceNumber: result.invoiceNumber,
        provider: result.provider,
        providerRef: result.providerRef,
        xmlPath: result.xmlPath ?? null,
        pdfPath: result.pdfPath ?? null,
        issuedAt: status === EInvoiceStatus.issued ? new Date() : null,
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
}
