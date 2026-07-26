import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { AuthUser } from './jwt.strategy';
import { hasLedgerPermission } from './permission-flags';

@Injectable()
export class LedgerPermissionGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    if (!request.user || !hasLedgerPermission(request.user)) {
      throw new ForbiddenException('ledger_permission_required');
    }
    return true;
  }
}
