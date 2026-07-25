import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { StoresService } from './stores.service';

type StoreUpsertBody = {
  code?: string;
  name?: string;
  debtOverdueDays?: number;
  largeDebtThresholdVnd?: number | null;
};

@Controller('stores')
@UseGuards(JwtAuthGuard)
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get()
  list(@Req() req: { user: AuthUser }) {
    return this.storesService.findForUser(
      req.user.role as Role,
      req.user.storeIds,
    );
  }

  @Post()
  create(
    @Req() req: { user: AuthUser },
    @Body() body: StoreUpsertBody,
  ) {
    const data = this.validateStoreBody(body, { requireCodeName: true });
    return this.storesService.create(req.user, data);
  }

  @Patch(':id')
  update(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: StoreUpsertBody,
  ) {
    const data = this.validateStoreBody(body, { requireCodeName: false });
    if (Object.keys(data).length === 0) {
      throw new BadRequestException('At least one store field is required');
    }
    return this.storesService.update(req.user, id, data);
  }

  @Patch(':id/debt-overdue-days')
  setDebtOverdueDays(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { debtOverdueDays?: number },
  ) {
    if (
      body.debtOverdueDays == null ||
      !Number.isInteger(body.debtOverdueDays) ||
      body.debtOverdueDays < 1
    ) {
      throw new BadRequestException(
        'debtOverdueDays must be a positive integer',
      );
    }
    return this.storesService.setDebtOverdueDays(
      req.user,
      id,
      body.debtOverdueDays,
    );
  }

  @Patch(':id/vat')
  setVat(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body()
    body: { vatEnabled?: boolean; defaultVatRateBps?: number },
  ) {
    if (body.vatEnabled === undefined && body.defaultVatRateBps === undefined) {
      throw new BadRequestException(
        'vatEnabled or defaultVatRateBps is required',
      );
    }
    if (
      body.defaultVatRateBps !== undefined &&
      (!Number.isInteger(body.defaultVatRateBps) ||
        body.defaultVatRateBps < 0 ||
        body.defaultVatRateBps > 10000)
    ) {
      throw new BadRequestException(
        'defaultVatRateBps must be an integer 0..10000',
      );
    }
    return this.storesService.setVatSettings(req.user, id, body);
  }

  private validateStoreBody(
    body: StoreUpsertBody,
    options: { requireCodeName: boolean },
  ) {
    const data: StoreUpsertBody = {};
    if (body.code !== undefined) {
      const code = body.code.trim().toUpperCase();
      if (!code || code.length > 32) {
        throw new BadRequestException('code must be 1..32 characters');
      }
      data.code = code;
    } else if (options.requireCodeName) {
      throw new BadRequestException('code is required');
    }

    if (body.name !== undefined) {
      const name = body.name.trim();
      if (!name || name.length > 120) {
        throw new BadRequestException('name must be 1..120 characters');
      }
      data.name = name;
    } else if (options.requireCodeName) {
      throw new BadRequestException('name is required');
    }

    if (body.debtOverdueDays !== undefined) {
      if (
        !Number.isInteger(body.debtOverdueDays) ||
        body.debtOverdueDays < 1
      ) {
        throw new BadRequestException(
          'debtOverdueDays must be a positive integer',
        );
      }
      data.debtOverdueDays = body.debtOverdueDays;
    }

    if (body.largeDebtThresholdVnd !== undefined) {
      if (body.largeDebtThresholdVnd !== null) {
        if (
          !Number.isSafeInteger(body.largeDebtThresholdVnd) ||
          body.largeDebtThresholdVnd <= 0
        ) {
          throw new BadRequestException(
            'largeDebtThresholdVnd must be a positive integer or null',
          );
        }
      }
      data.largeDebtThresholdVnd = body.largeDebtThresholdVnd;
    }

    return data;
  }
}
