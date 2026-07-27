import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthUser } from '../auth/jwt.strategy';
import {
  CreateUserBody,
  UpdateUserBody,
  parseCreateUserBody,
  parsePasswordBody,
  parseUpdateUserBody,
} from './user-validation';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  list(@Req() req: { user: AuthUser }) {
    return this.usersService.findForUser(req.user);
  }

  @Post()
  create(@Req() req: { user: AuthUser }, @Body() body: CreateUserBody) {
    return this.usersService.create(req.user, parseCreateUserBody(body));
  }

  @Patch(':id')
  update(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: UpdateUserBody,
  ) {
    return this.usersService.update(req.user, id, parseUpdateUserBody(body));
  }

  @Patch(':id/password')
  setPassword(
    @Req() req: { user: AuthUser },
    @Param('id') id: string,
    @Body() body: { password?: unknown },
  ) {
    return this.usersService.setPassword(req.user, id, parsePasswordBody(body));
  }
}
