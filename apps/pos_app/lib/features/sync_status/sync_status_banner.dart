import 'package:flutter/material.dart';

import '../../data/local/database.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatusSnapshot>(
      stream: db.watchSyncStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null || !status.isVisible) {
          return const SizedBox.shrink();
        }

        final colorScheme = Theme.of(context).colorScheme;
        final background = status.lastError != null
            ? colorScheme.errorContainer
            : colorScheme.tertiaryContainer;
        final foreground = status.lastError != null
            ? colorScheme.onErrorContainer
            : colorScheme.onTertiaryContainer;

        return Material(
          color: background,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  status.lastError != null
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_upload_outlined,
                  color: foreground,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _message(status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _message(SyncStatusSnapshot status) {
    final parts = <String>[];
    if (status.pendingCount > 0) {
      parts.add('${status.pendingCount} đang chờ đồng bộ');
    }
    if (status.lastError != null) {
      parts.add('Lỗi: ${status.lastError}');
    }
    return parts.join(' · ');
  }
}
