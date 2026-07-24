import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/sync/pull_catalog.dart';
import '../shifts/shift_repository.dart';
import 'cash_voucher_service.dart';
import 'record_cash_voucher_sheet.dart';

class CashVoucherRow {
  const CashVoucherRow({
    required this.voucher,
    required this.categoryName,
  });

  final CashVouchersLocalData voucher;
  final String categoryName;
}

class CashLedgerPage extends StatefulWidget {
  const CashLedgerPage({
    super.key,
    required this.db,
    required this.cashVoucherService,
    required this.shiftRepository,
    required this.pullCatalog,
    required this.storeId,
    required this.userId,
  });

  final AppDatabase db;
  final CashVoucherService cashVoucherService;
  final ShiftRepository shiftRepository;
  final PullCatalog pullCatalog;
  final String storeId;
  final String userId;

  @override
  State<CashLedgerPage> createState() => _CashLedgerPageState();
}

class _CashLedgerPageState extends State<CashLedgerPage> {
  String? _shiftId;
  String? _loadError;
  Map<String, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    try {
      final shift = await widget.shiftRepository.requireOpenShift(
        storeId: widget.storeId,
        userId: widget.userId,
      );
      var categories = await widget.db.select(widget.db.cashCategoriesLocal).get();
      if (categories.isEmpty) {
        await widget.pullCatalog.pullCatalog(widget.storeId);
        categories = await widget.db.select(widget.db.cashCategoriesLocal).get();
      }
      if (!mounted) return;
      setState(() {
        _shiftId = shift.id;
        _categoryNames = {for (final c in categories) c.id: c.name};
      });
    } on NoOpenShiftException {
      if (!mounted) return;
      setState(() => _loadError = 'Không có ca đang mở');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Không tải được sổ thu chi');
    }
  }

  Stream<List<CashVoucherRow>> _watchVouchers(String shiftId) {
    return (widget.db.select(widget.db.cashVouchersLocal)
          ..where((v) => v.shiftId.equals(shiftId))
          ..orderBy([(v) => OrderingTerm.desc(v.clientCreatedAt)]))
        .watch()
        .map(
          (vouchers) => vouchers
              .map(
                (voucher) => CashVoucherRow(
                  voucher: voucher,
                  categoryName:
                      _categoryNames[voucher.categoryId] ?? voucher.categoryId,
                ),
              )
              .toList(),
        );
  }

  Future<void> _openVoucherSheet(String direction) async {
    final created = await RecordCashVoucherSheet.show(
      context,
      direction: direction,
      db: widget.db,
      cashVoucherService: widget.cashVoucherService,
    );
    if (!mounted || !created) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(direction == 'in' ? 'Đã ghi phiếu thu' : 'Đã ghi phiếu chi')),
    );
  }

  String _channelLabel(String channel) =>
      channel == 'cash' ? 'Tiền mặt' : 'Chuyển khoản';

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ thu chi')),
      floatingActionButton: _shiftId == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'voucher-in',
                  onPressed: () => _openVoucherSheet('in'),
                  icon: const Icon(Icons.add),
                  label: const Text('Phiếu thu'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'voucher-out',
                  onPressed: () => _openVoucherSheet('out'),
                  icon: const Icon(Icons.remove),
                  label: const Text('Phiếu chi'),
                ),
              ],
            ),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : _shiftId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<CashVoucherRow>>(
              stream: _watchVouchers(_shiftId!),
              builder: (context, snapshot) {
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('Chưa có phiếu trong ca này'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 140),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final voucher = row.voucher;
                    final isIn = voucher.direction == 'in';
                    final prefix = isIn ? '+' : '−';
                    final color = isIn ? Colors.green : Colors.red;
                    return ListTile(
                      title: Text(row.categoryName),
                      subtitle: Text(
                        '${_channelLabel(voucher.channel)} · ${_formatTime(voucher.clientCreatedAt)}',
                      ),
                      trailing: Text(
                        '$prefix${voucher.amountVnd} VND',
                        style: TextStyle(color: color),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
