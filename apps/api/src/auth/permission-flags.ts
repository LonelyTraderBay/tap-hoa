import { Role } from '@prisma/client';

type PermissionUser = {
  role: string;
  canLedger?: boolean;
  canEinvoice?: boolean;
};

export type EffectivePermissions = {
  canLedger: boolean;
  canEinvoice: boolean;
};

export function effectivePermissions(user: PermissionUser): EffectivePermissions {
  if (user.role === Role.owner) {
    return { canLedger: true, canEinvoice: true };
  }
  if (user.role !== Role.store_manager) {
    return { canLedger: false, canEinvoice: false };
  }
  return {
    canLedger: user.canLedger === true,
    canEinvoice: user.canEinvoice === true,
  };
}

export function hasLedgerPermission(user: PermissionUser): boolean {
  return effectivePermissions(user).canLedger;
}

export function hasEinvoicePermission(user: PermissionUser): boolean {
  return effectivePermissions(user).canEinvoice;
}
