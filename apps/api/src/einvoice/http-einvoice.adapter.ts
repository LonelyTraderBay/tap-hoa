import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  AdjustEInvoiceInput,
  CancelEInvoiceInput,
  EInvoiceAdapter,
  IssueEInvoiceInput,
  IssueEInvoiceResult,
} from './einvoice.adapter';

const ALLOWED_STATUSES = new Set(['issued', 'pending_sign', 'failed']);

type ProviderIssueBody = {
  providerRef?: string;
  invoiceNumber?: string;
  status?: string;
  xmlPath?: string;
  pdfPath?: string;
};

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
    this.validateEndpoint(url, 'EINVOICE_HTTP_URL');
    this.validateEndpoint(this.cancelUrl(url), 'EINVOICE_HTTP_CANCEL_URL');
    this.validateEndpoint(this.adjustUrl(url), 'EINVOICE_HTTP_ADJUST_URL');
  }

  private validateEndpoint(url: string, envName: string) {
    try {
      const parsed = new URL(url);
      const allowHttp =
        process.env.EINVOICE_HTTP_ALLOW_INSECURE === '1' ||
        parsed.hostname === '127.0.0.1' ||
        parsed.hostname === 'localhost';
      if (parsed.protocol !== 'https:' && !allowHttp) {
        throw new Error(`${envName} must be https`);
      }
      if (
        parsed.hostname === 'metadata' ||
        parsed.hostname.endsWith('.internal')
      ) {
        throw new Error(`${envName} host not allowlisted`);
      }
    } catch (e) {
      this.logger.error(`einvoice http config invalid: ${String(e)}`);
      throw e;
    }
  }

  private cancelUrl(issueUrl: string): string {
    const configured = process.env.EINVOICE_HTTP_CANCEL_URL?.trim();
    if (configured) return configured;
    const derived = issueUrl.replace(/\/issue\/?$/i, '/cancel');
    return derived === issueUrl ? `${issueUrl.replace(/\/$/, '')}/cancel` : derived;
  }

  private adjustUrl(issueUrl: string): string {
    const configured = process.env.EINVOICE_HTTP_ADJUST_URL?.trim();
    if (configured) return configured;
    const derived = issueUrl.replace(/\/issue\/?$/i, '/adjust');
    return derived === issueUrl ? `${issueUrl.replace(/\/$/, '')}/adjust` : derived;
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

  private parseIssueBody(body: ProviderIssueBody): IssueEInvoiceResult {
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
  }

  private async postForIssueResult(
    url: string,
    headers: Record<string, string>,
    payload: string,
    logPrefix: string,
  ): Promise<IssueEInvoiceResult> {
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
            `${logPrefix} http ${res.status} attempt=${attempt}: ${this.redact(text)}`,
          );
          if (this.isRetryableStatus(res.status) && attempt < this.maxRetries) {
            await this.sleep(200 * Math.pow(2, attempt));
            continue;
          }
          throw new BadRequestException(
            `einvoice_provider_error:${res.status}`,
          );
        }

        try {
          return this.parseIssueBody((await res.json()) as ProviderIssueBody);
        } catch (err) {
          if (err instanceof BadRequestException) throw err;
          throw new BadRequestException('einvoice_provider_invalid_json');
        }
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
            `${logPrefix} http transport retry attempt=${attempt}: ${name}`,
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
          `${logPrefix} http transport failed: ${this.redact(String(err))}`,
        );
        throw new ServiceUnavailableException('einvoice_provider_unreachable');
      }
    }
    throw lastError instanceof Error
      ? lastError
      : new ServiceUnavailableException('einvoice_provider_unreachable');
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
      'Idempotency-Key':
        input.saleIds && input.saleIds.length > 1
          ? `batch:${input.saleIds.join(',')}`
          : input.saleId,
    };
    const apiKey = process.env.EINVOICE_HTTP_API_KEY?.trim();
    if (apiKey) {
      headers.authorization = `Bearer ${apiKey}`;
    }
    const payload = JSON.stringify({
      saleId: input.saleId,
      saleIds: input.saleIds ?? [input.saleId],
      totalVnd: input.totalVnd,
      buyerTaxCode: input.buyerTaxCode ?? null,
      templateCode: input.templateCode ?? null,
      serial: input.serial ?? null,
      lines: input.lines ?? [],
    });

    return this.postForIssueResult(url, headers, payload, 'einvoice');
  }

  async cancel(input: CancelEInvoiceInput): Promise<void> {
    const issueUrl = process.env.EINVOICE_HTTP_URL?.trim();
    if (!issueUrl) {
      throw new ServiceUnavailableException(
        'EINVOICE_HTTP_URL is required when EINVOICE_PROVIDER=http',
      );
    }
    const url = this.cancelUrl(issueUrl);
    const headers: Record<string, string> = {
      'content-type': 'application/json',
      accept: 'application/json',
      'Idempotency-Key': `cancel:${input.invoiceId}`,
    };
    const apiKey = process.env.EINVOICE_HTTP_API_KEY?.trim();
    if (apiKey) {
      headers.authorization = `Bearer ${apiKey}`;
    }
    const payload = JSON.stringify({
      invoiceId: input.invoiceId,
      providerRef: input.providerRef ?? null,
      reason: input.reason,
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
            `einvoice cancel http ${res.status} attempt=${attempt}: ${this.redact(text)}`,
          );
          if (this.isRetryableStatus(res.status) && attempt < this.maxRetries) {
            await this.sleep(200 * Math.pow(2, attempt));
            continue;
          }
          throw new BadRequestException(
            `einvoice_provider_cancel_error:${res.status}`,
          );
        }

        const text = await res.text().catch(() => '');
        if (text.trim()) {
          let body: { status?: string };
          try {
            body = JSON.parse(text) as typeof body;
          } catch {
            throw new BadRequestException('einvoice_provider_invalid_json');
          }
          if (body.status && body.status !== 'cancelled') {
            throw new BadRequestException(
              `einvoice_provider_unknown_status:${body.status}`,
            );
          }
        }
        return;
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
            `einvoice cancel http transport retry attempt=${attempt}: ${name}`,
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
          `einvoice cancel http transport failed: ${this.redact(String(err))}`,
        );
        throw new ServiceUnavailableException('einvoice_provider_unreachable');
      }
    }
    throw lastError instanceof Error
      ? lastError
      : new ServiceUnavailableException('einvoice_provider_unreachable');
  }

  async adjust(input: AdjustEInvoiceInput): Promise<IssueEInvoiceResult> {
    const issueUrl = process.env.EINVOICE_HTTP_URL?.trim();
    if (!issueUrl) {
      throw new ServiceUnavailableException(
        'EINVOICE_HTTP_URL is required when EINVOICE_PROVIDER=http',
      );
    }
    const url = this.adjustUrl(issueUrl);
    const headers: Record<string, string> = {
      'content-type': 'application/json',
      accept: 'application/json',
      'Idempotency-Key': `adjust:${input.invoiceId}`,
    };
    const apiKey = process.env.EINVOICE_HTTP_API_KEY?.trim();
    if (apiKey) {
      headers.authorization = `Bearer ${apiKey}`;
    }
    const payload = JSON.stringify({
      invoiceId: input.invoiceId,
      providerRef: input.providerRef ?? null,
      originalInvoiceNumber: input.originalInvoiceNumber ?? null,
      saleIds: input.saleIds,
      totalVnd: input.totalVnd,
      reason: input.reason,
      lines: input.lines ?? [],
    });

    return this.postForIssueResult(url, headers, payload, 'einvoice adjust');
  }
}
