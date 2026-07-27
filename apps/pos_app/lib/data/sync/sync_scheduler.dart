import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pos_app/data/local/local_backup_service.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/data/sync/pull_catalog.dart';

// Catalog data (products, prices, stock, customers, cash categories...)
// changes far less often than the outbox drains, so background pull runs on
// its own cadence rather than reusing the 15s push tick: frequent enough
// that a price change made elsewhere shows up within about a minute,
// without competing with push traffic or hammering the server.
const Duration catalogPullInterval = Duration(seconds: 60);

class SyncScheduler extends StatefulWidget {
  const SyncScheduler({
    super.key,
    required this.outboxWorker,
    required this.backupService,
    required this.pullCatalog,
    required this.child,
  });

  final OutboxWorker outboxWorker;
  final LocalBackupService backupService;
  final PullCatalog pullCatalog;
  final Widget child;

  @override
  State<SyncScheduler> createState() => SyncSchedulerState();
}

class SyncSchedulerState extends State<SyncScheduler>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _backupTimer;
  Timer? _pullTimer;
  bool _backupRunning = false;

  // SyncScheduler wraps the whole app above login/store-selection/shift
  // opening, so it has no inherent notion of "current store" — this is set
  // once a shift is opened and a store becomes active (see setActiveStore).
  String? _activeStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    _backupTimer = Timer.periodic(
      localBackupCheckInterval,
      (_) => _backupTick(),
    );
    unawaited(_tick());
    unawaited(_backupTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backupTimer?.cancel();
    _pullTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_tick());
      unawaited(_backupTick());
      if (_activeStoreId != null) {
        unawaited(_pullTick());
      }
    }
  }

  Future<void> syncNow() => _tick();

  /// Registers which store the device is currently operating on (called once
  /// a shift is opened / PosPage is reached) and starts/restarts periodic
  /// background catalog pull for that store. Safe to call again later (e.g.
  /// close shift → open a new one for a different store on the same device
  /// session) — it just re-targets the pull at the newly active store.
  ///
  /// Pulls once immediately so a freshly-opened shift doesn't wait a full
  /// [catalogPullInterval] for its first background pull.
  void setActiveStore(String storeId) {
    _activeStoreId = storeId;
    _pullTimer?.cancel();
    _pullTimer = Timer.periodic(catalogPullInterval, (_) => _pullTick());
    unawaited(_pullTick());
  }

  Future<void> _tick() => widget.outboxWorker.tick();

  Future<void> _pullTick() async {
    final storeId = _activeStoreId;
    if (storeId == null) {
      return;
    }
    try {
      await widget.pullCatalog.pullCatalog(storeId);
    } catch (_) {
      // Pull must never crash the app or block POS operations — a network
      // blip or server downtime just retries on the next periodic tick.
    }
  }

  Future<void> _backupTick() async {
    if (_backupRunning) {
      return;
    }
    _backupRunning = true;
    try {
      await widget.backupService.backupIfDue();
    } catch (_) {
      // Backup must never block or roll back POS operations.
    } finally {
      _backupRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
