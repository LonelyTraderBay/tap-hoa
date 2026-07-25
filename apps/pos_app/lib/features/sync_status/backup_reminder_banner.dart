import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local/local_backup_service.dart';

class BackupReminderBanner extends StatefulWidget {
  const BackupReminderBanner({super.key, required this.backupService});

  final LocalBackupService backupService;

  @override
  State<BackupReminderBanner> createState() => _BackupReminderBannerState();
}

class _BackupReminderBannerState extends State<BackupReminderBanner>
    with WidgetsBindingObserver {
  Timer? _timer;
  LocalBackupSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _load());
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    try {
      final snapshot = await widget.backupService.snapshot();
      if (!mounted) {
        return;
      }
      setState(() => _snapshot = snapshot);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _snapshot = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.isStale) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.backup_outlined,
              color: colorScheme.onErrorContainer,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _message(snapshot),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(LocalBackupSnapshot snapshot) {
    final lastBackupAt = snapshot.lastBackupAt;
    if (lastBackupAt == null) {
      return 'Chưa có sao lưu SQLite local; mở Diagnostics sync để sao lưu thủ công.';
    }
    return 'Sao lưu SQLite local đã quá 24h; mở Diagnostics sync để sao lưu thủ công.';
  }
}
