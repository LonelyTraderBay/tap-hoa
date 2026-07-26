import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { AuthUser } from './jwt.strategy';
import { hasEinvoicePermission } from './permission-flags';

@Injectable()
export class EInvoicePermissionGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    if (!request.user || !hasEinvoicePermission(request.user)) {
      throw new ForbiddenException('einvoice_permission_required');
    }
    return true;
  }
}
