import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';

/**
 * Generic HTTP e-invoice gateway.
 * Enable with EINVOICE_PROVIDER=http and EINVOICE_HTTP_URL.
 */
@Injectable()
export class HttpEInvoiceAdapter implements EInvoiceAdapter {
  readonly providerName = 'http';
  private readonly logger = new Logger(HttpEInvoiceAdapter.name);

  async issue(input: IssueEInvoiceInput): Promise<IssueEInvoiceResult> {
    const url = process.env.EINVOICE_HTTP_URL?.trim();
    if (!url) {
      throw new ServiceUnavailableException(
        'EINVOICE_HTTP_URL is required when EINVOICE_PROVIDER=http',
      );
    }
    const headers: Record<string, string> = {
      'content-type': 'application/json',
      accept: 'application/json',
    };
    const apiKey = process.env.EINVOICE_HTTP_API_KEY?.trim();
    if (apiKey) {
      headers.authorization = `Bearer ${apiKey}`;
    }

    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          saleId: input.saleId,
          totalVnd: input.totalVnd,
          buyerTaxCode: input.buyerTaxCode ?? null,
          templateCode: input.templateCode ?? null,
          serial: input.serial ?? null,
          lines: input.lines ?? [],
        }),
      });
    } catch (err) {
      this.logger.error(`einvoice http transport failed: ${String(err)}`);
      throw new ServiceUnavailableException('einvoice_provider_unreachable');
    }

    if (!res.ok) {
      const text = await res.text().catch(() => '');
      this.logger.warn(`einvoice http ${res.status}: ${text.slice(0, 200)}`);
      throw new BadRequestException(
        `einvoice_provider_error:${res.status}`,
      );
    }

    const body = (await res.json()) as {
      providerRef?: string;
      invoiceNumber?: string;
      status?: string;
      xmlPath?: string;
      pdfPath?: string;
    };
    if (!body.providerRef || !body.invoiceNumber) {
      throw new BadRequestException('einvoice_provider_invalid_response');
    }
    const status =
      body.status === 'pending_sign' ? 'pending_sign' : 'issued';
    return {
      provider: this.providerName,
      providerRef: body.providerRef,
      invoiceNumber: body.invoiceNumber,
      status,
      xmlPath: body.xmlPath,
      pdfPath: body.pdfPath,
    };
  }
}
