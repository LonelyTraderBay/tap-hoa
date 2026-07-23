import 'dart:async';

import 'package:flutter/material.dart';

import 'data/sync/outbox_worker.dart';

class SyncScheduler extends StatefulWidget {
  const SyncScheduler({
    super.key,
    required this.outboxWorker,
    required this.child,
  });

  final OutboxWorker outboxWorker;
  final Widget child;

  @override
  State<SyncScheduler> createState() => SyncSchedulerState();
}

class SyncSchedulerState extends State<SyncScheduler>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    unawaited(_tick());
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
      unawaited(_tick());
    }
  }

  Future<void> syncNow() => _tick();

  Future<void> _tick() => widget.outboxWorker.tick();

  @override
  Widget build(BuildContext context) => widget.child;
}
