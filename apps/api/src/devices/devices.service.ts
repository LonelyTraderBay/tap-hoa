import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { Role } from '@prisma/client';
import { existsSync, readFileSync } from 'fs';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';

type AdminMessaging = {
  sendEachForMulticast: (msg: {
    tokens: string[];
    notification: { title: string; body: string };
    data?: Record<string, string>;
  }) => Promise<{ successCount: number }>;
};

@Injectable()
export class DevicesService {
  private readonly logger = new Logger(DevicesService.name);
  private messaging: AdminMessaging | null | undefined;

  constructor(private readonly prisma: PrismaService) {}

  private getMessaging(): AdminMessaging | null {
    if (this.messaging !== undefined) {
      return this.messaging;
    }
    const path = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
    if (!path || !existsSync(path)) {
      this.messaging = null;
      return null;
    }
    try {
      // Optional dependency: present when installed + env configured.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const admin = require('firebase-admin') as {
        apps: unknown[];
        initializeApp: (opts: { credential: unknown }) => void;
        credential: { cert: (s: unknown) => unknown };
        messaging: () => AdminMessaging;
      };
      if (!admin.apps.length) {
        const serviceAccount = JSON.parse(readFileSync(path, 'utf8'));
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      }
      this.messaging = admin.messaging();
      return this.messaging;
    } catch (error) {
      this.logger.warn(`Firebase admin init failed: ${String(error)}`);
      this.messaging = null;
      return null;
    }
  }

  async registerToken(
    user: AuthUser,
    input: { deviceId: string; token: string; platform: string },
  ) {
    if (!input.deviceId.trim() || !input.token.trim()) {
      throw new BadRequestException('deviceId and token are required');
    }
    const row = await this.prisma.devicePushToken.upsert({
      where: { deviceId: input.deviceId.trim() },
      create: {
        deviceId: input.deviceId.trim(),
        userId: user.userId,
        token: input.token.trim(),
        platform: input.platform.trim() || 'unknown',
      },
      update: {
        userId: user.userId,
        token: input.token.trim(),
        platform: input.platform.trim() || 'unknown',
      },
    });
    return { id: row.id, deviceId: row.deviceId };
  }

  /** Best-effort FCM send; no-ops when FIREBASE_SERVICE_ACCOUNT is unset. */
  async notifyUser(
    userId: string,
    notification: {
      title: string;
      body: string;
      data?: Record<string, string>;
    },
  ) {
    const tokens = await this.prisma.devicePushToken.findMany({
      where: { userId },
    });
    if (tokens.length === 0) {
      return { sent: 0 };
    }
    const messaging = this.getMessaging();
    if (!messaging) {
      this.logger.debug(
        `FCM skipped (no FIREBASE_SERVICE_ACCOUNT): ${notification.title} → ${userId} (${tokens.length} tokens)`,
      );
      return { sent: 0 };
    }
    try {
      const result = await messaging.sendEachForMulticast({
        tokens: tokens.map((t) => t.token),
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data,
      });
      return { sent: result.successCount };
    } catch (error) {
      this.logger.warn(`FCM send failed: ${String(error)}`);
      return { sent: 0 };
    }
  }

  async notifyStoreManagers(
    storeId: string,
    notification: {
      title: string;
      body: string;
      data?: Record<string, string>;
    },
  ) {
    const memberships = await this.prisma.userStore.findMany({
      where: {
        storeId,
        user: { role: { in: [Role.owner, Role.store_manager] } },
      },
      select: { userId: true },
    });
    const owners = await this.prisma.user.findMany({
      where: { role: Role.owner },
      select: { id: true },
    });
    const userIds = [
      ...new Set([
        ...memberships.map((m) => m.userId),
        ...owners.map((u) => u.id),
      ]),
    ];
    let sent = 0;
    for (const userId of userIds) {
      const result = await this.notifyUser(userId, notification);
      sent += result.sent;
    }
    return { sent };
  }

  async notifyLowStock(
    user: AuthUser,
    input: {
      storeId: string;
      productId: string;
      productName: string;
      qty: string;
    },
  ) {
    if (!input.storeId.trim() || !input.productId.trim()) {
      throw new BadRequestException('storeId and productId are required');
    }
    void user;
    return this.notifyStoreManagers(input.storeId, {
      title: 'Tồn thấp',
      body: `${input.productName || input.productId}: còn ${input.qty}`,
      data: {
        type: 'low_stock',
        storeId: input.storeId,
        productId: input.productId,
      },
    });
  }
}
