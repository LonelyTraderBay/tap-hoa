import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import { CustomersService } from './customers.service';
import { CreateCustomerDto } from './dto/create-customer.dto';

@Controller('customers')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Get()
  list(
    @Req() req: { user: AuthUser },
    @Query('storeId') storeId?: string,
    @Query('withDebt') withDebt?: string,
  ) {
    if (!storeId) {
      throw new BadRequestException('storeId is required');
    }
    return this.customersService.list(req.user, storeId, withDebt === 'true');
  }

  @Post()
  create(
    @Req() req: { user: AuthUser },
    @Body() dto: CreateCustomerDto,
  ) {
    return this.customersService.create(req.user, dto);
  }
}
