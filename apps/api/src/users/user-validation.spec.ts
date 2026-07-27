import { BadRequestException } from '@nestjs/common';
import { Role } from '@prisma/client';
import {
  assertCashierPermissionFlags,
  parseCreateUserBody,
  parseSetPasswordBody,
  parseStoreIds,
  parseUpdateUserBody,
} from './user-validation';

describe('parseCreateUserBody', () => {
  const validBody = {
    phone: '0912345678',
    name: 'Nguyen Van A',
    password: '123456',
    role: 'cashier',
    storeIds: ['store-1'],
  };

  it('normalizes a valid body and defaults permission flags to false', () => {
    expect(parseCreateUserBody({ ...validBody, name: '  Nguyen Van A ' })).toEqual({
      phone: '0912345678',
      name: 'Nguyen Van A',
      password: '123456',
      role: Role.cashier,
      storeIds: ['store-1'],
      canLedger: false,
      canEinvoice: false,
    });
  });

  it('rejects a phone that is not 8..15 digits', () => {
    expect(() => parseCreateUserBody({ ...validBody, phone: '0912345' })).toThrow(
      BadRequestException,
    );
    expect(() =>
      parseCreateUserBody({ ...validBody, phone: '0912345678901234' }),
    ).toThrow(BadRequestException);
    expect(() => parseCreateUserBody({ ...validBody, phone: '091234567a' })).toThrow(
      BadRequestException,
    );
    expect(() => parseCreateUserBody({ ...validBody, phone: undefined })).toThrow(
      BadRequestException,
    );
  });

  it('rejects a name that is empty or longer than 120 characters', () => {
    expect(() => parseCreateUserBody({ ...validBody, name: '   ' })).toThrow(
      BadRequestException,
    );
    expect(() =>
      parseCreateUserBody({ ...validBody, name: 'a'.repeat(121) }),
    ).toThrow(BadRequestException);
  });

  it('rejects a password shorter than 6 characters', () => {
    expect(() => parseCreateUserBody({ ...validBody, password: '12345' })).toThrow(
      BadRequestException,
    );
  });

  it('rejects an unknown role', () => {
    expect(() => parseCreateUserBody({ ...validBody, role: 'admin' })).toThrow(
      BadRequestException,
    );
  });

  it('rejects empty or malformed storeIds', () => {
    expect(() => parseCreateUserBody({ ...validBody, storeIds: [] })).toThrow(
      BadRequestException,
    );
    expect(() => parseCreateUserBody({ ...validBody, storeIds: [1] })).toThrow(
      BadRequestException,
    );
    expect(() => parseCreateUserBody({ ...validBody, storeIds: 'store-1' })).toThrow(
      BadRequestException,
    );
  });

  it('refuses ledger/e-invoice flags on a cashier', () => {
    expect(() =>
      parseCreateUserBody({ ...validBody, role: 'cashier', canLedger: true }),
    ).toThrow(BadRequestException);
    expect(() =>
      parseCreateUserBody({ ...validBody, role: 'cashier', canEinvoice: true }),
    ).toThrow(BadRequestException);
    expect(
      parseCreateUserBody({
        ...validBody,
        role: 'store_manager',
        canLedger: true,
      }).canLedger,
    ).toBe(true);
  });
});

describe('parseStoreIds', () => {
  it('trims and de-duplicates ids', () => {
    expect(parseStoreIds([' s1 ', 's1', 's2'])).toEqual(['s1', 's2']);
  });
});

describe('parseUpdateUserBody', () => {
  it('keeps only the provided fields', () => {
    expect(parseUpdateUserBody({ active: false })).toEqual({ active: false });
    expect(parseUpdateUserBody({ name: ' Chi B ', role: 'store_manager' })).toEqual({
      name: 'Chi B',
      role: Role.store_manager,
    });
  });

  it('rejects an empty body', () => {
    expect(() => parseUpdateUserBody({})).toThrow(BadRequestException);
  });

  it('rejects non-boolean flags', () => {
    expect(() => parseUpdateUserBody({ active: 'false' })).toThrow(
      BadRequestException,
    );
    expect(() => parseUpdateUserBody({ canLedger: 1 })).toThrow(
      BadRequestException,
    );
  });

  it('does not allow changing the phone', () => {
    expect(() =>
      parseUpdateUserBody({ phone: '0912345678' } as Record<string, unknown>),
    ).toThrow(BadRequestException);
  });
});

describe('assertCashierPermissionFlags', () => {
  it('allows a cashier without accounting flags', () => {
    expect(() =>
      assertCashierPermissionFlags(Role.cashier, false, false),
    ).not.toThrow();
  });

  it('allows an owner with accounting flags', () => {
    expect(() => assertCashierPermissionFlags(Role.owner, true, true)).not.toThrow();
  });

  it('blocks a cashier with accounting flags', () => {
    expect(() => assertCashierPermissionFlags(Role.cashier, true, false)).toThrow(
      BadRequestException,
    );
  });
});

describe('parseSetPasswordBody', () => {
  it('accepts 6 characters or more and no currentPassword', () => {
    expect(parseSetPasswordBody({ password: 'abcdef' })).toEqual({
      password: 'abcdef',
    });
  });

  it('rejects short or missing passwords', () => {
    expect(() => parseSetPasswordBody({ password: 'abc' })).toThrow(
      BadRequestException,
    );
    expect(() => parseSetPasswordBody({})).toThrow(BadRequestException);
  });

  it('passes through a valid currentPassword', () => {
    expect(
      parseSetPasswordBody({ password: 'abcdef', currentPassword: 'ghijkl' }),
    ).toEqual({ password: 'abcdef', currentPassword: 'ghijkl' });
  });

  it('rejects a non-string or empty currentPassword', () => {
    expect(() =>
      parseSetPasswordBody({ password: 'abcdef', currentPassword: 123 }),
    ).toThrow(BadRequestException);
    expect(() =>
      parseSetPasswordBody({ password: 'abcdef', currentPassword: '' }),
    ).toThrow(BadRequestException);
  });
});
