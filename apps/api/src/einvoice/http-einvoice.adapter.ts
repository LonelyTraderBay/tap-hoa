import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';

const ALLOWED_STATUSES = new Set(['issued', 'pending_sign', 'failed']);

/**
 * Generic HTTP e-invoice gateway.
 * Enable with EINVOICE_PROVIDER=http and EINVOICE_HTTP_URL (HTTPS in prod).
 */
@Injectable()
export class HttpEInvoiceAdapter implements EInvoiceAdapter, OnModuleInit {
  readonly providerName = 'http';
  private readonly logger = new Logger(HttpEInvoiceAdapter.name);
  private readonly timeoutMs = Number(
    process.env.EINVOICE_HTTP_TIMEOUT_MS ?? 15_000,
  );
  private readonly maxRetries = Number(
    process.env.EINVOICE_HTTP_MAX_RETRIES ?? 2,
  );

  onModuleInit() {
    const url = process.env.EINVOICE_HTTP_URL?.trim();
    if (process.env.EINVOICE_PROVIDER !== 'http') return;
    if (!url) {
      this.logger.error('EINVOICE_HTTP_URL missing for EINVOICE_PROVIDER=http');
      return;
    }
    try {
      const parsed = new URL(url);
      const allowHttp =
        process.env.EINVOICE_HTTP_ALLOW_INSECURE === '1' ||
        parsed.hostname === '127.0.0.1' ||
        parsed.hostname === 'localhost';
      if (parsed.protocol !== 'https:' && !allowHttp) {
        throw new Error('EINVOICE_HTTP_URL must be https');
      }
      if (
        parsed.hostname === 'metadata' ||
        parsed.hostname.endsWith('.internal')
      ) {
        throw new Error('EINVOICE_HTTP_URL host not allowlisted');
      }
    } catch (e) {
      this.logger.error(`einvoice http config invalid: ${String(e)}`);
      throw e;
    }
  }

  private sleep(ms: number) {
    return new Promise((r) => setTimeout(r, ms));
  }

  private redact(text: string): string {
    return text
      .replace(/Bearer\s+[^\s"]+/gi, 'Bearer ***')
      .replace(/"apiKey"\s*:\s*"[^"]*"/gi, '"apiKey":"***"')
      .slice(0, 200);
  }

  private isRetryableStatus(status: number): boolean {
    return status === 429 || status >= 500;
  }

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
      'Idempotency-Key': input.saleId,
    };
    const apiKey = process.env.EINVOICE_HTTP_API_KEY?.trim();
    if (apiKey) {
      headers.authorization = `Bearer ${apiKey}`;
    }
    const payload = JSON.stringify({
      saleId: input.saleId,
      totalVnd: input.totalVnd,
      buyerTaxCode: input.buyerTaxCode ?? null,
      templateCode: input.templateCode ?? null,
      serial: input.serial ?? null,
      lines: input.lines ?? [],
    });

    let lastError: unknown;
    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers,
          body: payload,
          signal: controller.signal,
        });
        clearTimeout(timer);

        if (!res.ok) {
          const text = await res.text().catch(() => '');
          this.logger.warn(
            `einvoice http ${res.status} attempt=${attempt}: ${this.redact(text)}`,
          );
          if (this.isRetryableStatus(res.status) && attempt < this.maxRetries) {
            await this.sleep(200 * Math.pow(2, attempt));
            continue;
          }
          throw new BadRequestException(
            `einvoice_provider_error:${res.status}`,
          );
        }

        let body: {
          providerRef?: string;
          invoiceNumber?: string;
          status?: string;
          xmlPath?: string;
          pdfPath?: string;
        };
        try {
          body = (await res.json()) as typeof body;
        } catch {
          throw new BadRequestException('einvoice_provider_invalid_json');
        }
        if (!body.providerRef || !body.invoiceNumber) {
          throw new BadRequestException('einvoice_provider_invalid_response');
        }
        if (body.xmlPath && !/^https?:\/\//i.test(body.xmlPath)) {
          throw new BadRequestException('einvoice_provider_invalid_xml_url');
        }
        if (body.pdfPath && !/^https?:\/\//i.test(body.pdfPath)) {
          throw new BadRequestException('einvoice_provider_invalid_pdf_url');
        }
        const rawStatus = body.status ?? 'issued';
        if (!ALLOWED_STATUSES.has(rawStatus)) {
          throw new BadRequestException(
            `einvoice_provider_unknown_status:${rawStatus}`,
          );
        }
        if (rawStatus === 'failed') {
          throw new BadRequestException('einvoice_provider_failed');
        }
        return {
          provider: this.providerName,
          providerRef: body.providerRef,
          invoiceNumber: body.invoiceNumber,
          status: rawStatus as 'issued' | 'pending_sign',
          xmlPath: body.xmlPath,
          pdfPath: body.pdfPath,
        };
      } catch (err) {
        clearTimeout(timer);
        lastError = err;
        const name = err instanceof Error ? err.name : '';
        const retryable =
          name === 'AbortError' ||
          name === 'TimeoutError' ||
          (err instanceof TypeError && /fetch/i.test(String(err)));
        if (retryable && attempt < this.maxRetries) {
          this.logger.warn(
            `einvoice http transport retry attempt=${attempt}: ${name}`,
          );
          await this.sleep(200 * Math.pow(2, attempt));
          continue;
        }
        if (
          err instanceof BadRequestException ||
          err instanceof ServiceUnavailableException
        ) {
          throw err;
        }
        this.logger.error(
          `einvoice http transport failed: ${this.redact(String(err))}`,
        );
        throw new ServiceUnavailableException('einvoice_provider_unreachable');
      }
    }
    throw lastError instanceof Error
      ? lastError
      : new ServiceUnavailableException('einvoice_provider_unreachable');
  }
}
