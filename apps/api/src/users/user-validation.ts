import { BadRequestException } from '@nestjs/common';
import { Role } from '@prisma/client';

export const USER_ROLES: Role[] = [Role.owner, Role.store_manager, Role.cashier];

export const MIN_PASSWORD_LENGTH = 6;

export type CreateUserBody = {
  phone?: unknown;
  name?: unknown;
  password?: unknown;
  role?: unknown;
  storeIds?: unknown;
  canLedger?: unknown;
  canEinvoice?: unknown;
};

export type CreateUserData = {
  phone: string;
  name: string;
  password: string;
  role: Role;
  storeIds: string[];
  canLedger: boolean;
  canEinvoice: boolean;
};

export type UpdateUserBody = {
  name?: unknown;
  role?: unknown;
  storeIds?: unknown;
  canLedger?: unknown;
  canEinvoice?: unknown;
  active?: unknown;
};

export type UpdateUserData = {
  name?: string;
  role?: Role;
  storeIds?: string[];
  canLedger?: boolean;
  canEinvoice?: boolean;
  active?: boolean;
};

export function parsePhone(value: unknown): string {
  if (typeof value !== 'string') {
    throw new BadRequestException('phone is required');
  }
  const phone = value.trim();
  if (!/^[0-9]{8,15}$/.test(phone)) {
    throw new BadRequestException('phone must be 8..15 digits');
  }
  return phone;
}

export function parseName(value: unknown): string {
  if (typeof value !== 'string') {
    throw new BadRequestException('name is required');
  }
  const name = value.trim();
  if (!name || name.length > 120) {
    throw new BadRequestException('name must be 1..120 characters');
  }
  return name;
}

export function parsePassword(value: unknown): string {
  if (typeof value !== 'string' || value.length < MIN_PASSWORD_LENGTH) {
    throw new BadRequestException(
      `password must be at least ${MIN_PASSWORD_LENGTH} characters`,
    );
  }
  return value;
}

export function parseRole(value: unknown): Role {
  if (typeof value !== 'string' || !USER_ROLES.includes(value as Role)) {
    throw new BadRequestException(
      `role must be one of ${USER_ROLES.join(', ')}`,
    );
  }
  return value as Role;
}

export function parseStoreIds(value: unknown): string[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new BadRequestException('storeIds must be a non-empty array');
  }
  const storeIds: string[] = [];
  for (const raw of value) {
    if (typeof raw !== 'string' || !raw.trim()) {
      throw new BadRequestException('storeIds must contain store ids');
    }
    const storeId = raw.trim();
    if (!storeIds.includes(storeId)) {
      storeIds.push(storeId);
    }
  }
  return storeIds;
}

export function parseBooleanField(field: string, value: unknown): boolean {
  if (typeof value !== 'boolean') {
    throw new BadRequestException(`${field} must be a boolean`);
  }
  return value;
}

/**
 * Thu ngân không bao giờ được cấp quyền sổ kế toán / hóa đơn điện tử.
 * effectivePermissions() đã bỏ qua cờ này lúc chạy, chặn ở đây để dữ liệu sạch.
 */
export function assertCashierPermissionFlags(
  role: Role,
  canLedger: boolean,
  canEinvoice: boolean,
): void {
  if (role === Role.cashier && (canLedger || canEinvoice)) {
    throw new BadRequestException(
      'cashier cannot have canLedger or canEinvoice',
    );
  }
}

export function parseCreateUserBody(body: CreateUserBody): CreateUserData {
  const phone = parsePhone(body.phone);
  const name = parseName(body.name);
  const password = parsePassword(body.password);
  const role = parseRole(body.role);
  const storeIds = parseStoreIds(body.storeIds);
  const canLedger =
    body.canLedger === undefined
      ? false
      : parseBooleanField('canLedger', body.canLedger);
  const canEinvoice =
    body.canEinvoice === undefined
      ? false
      : parseBooleanField('canEinvoice', body.canEinvoice);
  assertCashierPermissionFlags(role, canLedger, canEinvoice);
  return { phone, name, password, role, storeIds, canLedger, canEinvoice };
}

export function parseUpdateUserBody(body: UpdateUserBody): UpdateUserData {
  const data: UpdateUserData = {};
  if (body.name !== undefined) {
    data.name = parseName(body.name);
  }
  if (body.role !== undefined) {
    data.role = parseRole(body.role);
  }
  if (body.storeIds !== undefined) {
    data.storeIds = parseStoreIds(body.storeIds);
  }
  if (body.canLedger !== undefined) {
    data.canLedger = parseBooleanField('canLedger', body.canLedger);
  }
  if (body.canEinvoice !== undefined) {
    data.canEinvoice = parseBooleanField('canEinvoice', body.canEinvoice);
  }
  if (body.active !== undefined) {
    data.active = parseBooleanField('active', body.active);
  }
  if (Object.keys(data).length === 0) {
    throw new BadRequestException('At least one user field is required');
  }
  return data;
}

export type SetPasswordBody = {
  password?: unknown;
  currentPassword?: unknown;
};

export type SetPasswordData = {
  password: string;
  currentPassword?: string;
};

/**
 * `currentPassword` chỉ bắt buộc khi actor tự đổi mật khẩu của chính mình
 * (kiểm tra ở UsersService.setPassword) — ở đây chỉ parse nếu có mặt, không ép buộc,
 * vì owner reset mật khẩu người khác thì không cần trường này.
 */
export function parseSetPasswordBody(body: SetPasswordBody): SetPasswordData {
  const password = parsePassword(body.password);
  if (body.currentPassword === undefined) {
    return { password };
  }
  if (typeof body.currentPassword !== 'string' || !body.currentPassword) {
    throw new BadRequestException('currentPassword must be a string');
  }
  return { password, currentPassword: body.currentPassword };
}
