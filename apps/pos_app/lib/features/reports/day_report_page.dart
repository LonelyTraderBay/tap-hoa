import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'day_report_csv.dart';
import 'day_report_repository.dart';
import 'ict_date.dart';
import 'stock_on_hand_page.dart';
import 'stock_on_hand_repository.dart';
import '../pos/sale_return_service.dart';
import '../pos/sale_return_sheet.dart';
import '../../data/local/database.dart';
import '../shifts/shift_repository.dart';

class DayReportPage extends StatefulWidget {
  const DayReportPage({
    super.key,
    required this.repository,
    required this.stockOnHandRepository,
    required this.storeId,
    required this.role,
    this.database,
    this.shiftRepository,
  });

  final DayReportRepository repository;
  final StockOnHandRepository stockOnHandRepository;
  final String storeId;
  final String role;
  final AppDatabase? database;
  final ShiftRepository? shiftRepository;

  @override
  State<DayReportPage> createState() => _DayReportPageState();
}

class _DayReportPageState extends State<DayReportPage> {
  DateTime _selectedDate = ictToday();
  DayReport? _report;
  TopSkuReport? _topSkus;
  bool _isLoading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final storeId = widget.role == 'owner' ? null : widget.storeId;
      final results = await Future.wait([
        widget.repository.fetchDayReport(
          date: _selectedDate,
          storeId: storeId,
        ),
        widget.repository.fetchTopSkus(
          date: _selectedDate,
          storeId: storeId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as DayReport;
        _topSkus = results[1] as TopSkuReport;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được báo cáo';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || picked == _selectedDate) {
      return;
    }
    setState(() => _selectedDate = picked);
    await _loadReport();
  }

  String _formatDateLabel(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  void _openStockOnHand() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockOnHandPage(
          repository: widget.stockOnHandRepository,
          storeId: widget.storeId,
          role: widget.role,
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final report = _report;
    if (report == null) return;
    try {
      final rows = <({
        String storeCode,
        String storeName,
        int orderCount,
        int revenueVnd,
        int cashVnd,
        int transferVnd,
        int debtVnd,
      })>[];
      for (final store in report.byStore) {
        var code = store.storeId;
        var name = store.storeId;
        final db = widget.database;
        if (db != null) {
          final local = await (db.select(db.storesLocal)
                ..where((t) => t.id.equals(store.storeId)))
              .getSingleOrNull();
          if (local != null) {
            code = local.code;
            name = local.name;
          }
        }
        rows.add((
          storeCode: code,
          storeName: name,
          orderCount: store.orderCount,
          revenueVnd: store.revenueVnd,
          cashVnd: store.cashVnd,
          transferVnd: store.transferVnd,
          debtVnd: store.debtVnd,
        ));
      }
      final csv = dayReportToCsv(
        date: formatIctDate(_selectedDate),
        rows: rows,
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(dir.path, 'day-report-${formatIctDate(_selectedDate)}.csv'),
      );
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất CSV: ${file.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất CSV thất bại')),
      );
    }
  }

  void _openReturn() {
    final db = widget.database;
    final shifts = widget.shiftRepository;
    if (db == null || shifts == null) return;
    final canReturn =
        widget.role == 'owner' || widget.role == 'store_manager';
    if (!canReturn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thu ngân không được đổi trả')),
      );
      return;
    }
    showSaleReturnSheet(
      context,
      db: db,
      service: SaleReturnService(db: db, shiftRepository: shifts),
      storeId: widget.storeId,
      role: widget.role,
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final topSkus = _topSkus;
    final theme = Theme.of(context);
    final isOffline = report?.isOffline == true || topSkus?.isOffline == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo ngày'),
        actions: [
          IconButton(
            onPressed: _isLoading || _report == null ? null : _exportCsv,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất CSV',
          ),
          IconButton(
            onPressed: _isLoading ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Chọn ngày',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _message != null
          ? Center(child: Text(_message!))
          : report == null || topSkus == null
          ? const Center(child: Text('Không có dữ liệu'))
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (isOffline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Dữ liệu cửa hàng hiện tại (ngoại tuyến)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    _formatDateLabel(_selectedDate),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.totalRevenueVnd} VND',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng doanh thu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Top hàng bán chạy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (topSkus.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Chưa có bán trong ngày',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...topSkus.items.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      final grossLabel = item.estimatedGrossVnd?.toString() ?? '—';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '#$rank',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'SL: ${item.qty} · DT: ${item.revenueVnd} VND · Lãi: $grossLabel',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  ...report.byStore.map((store) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${store.revenueVnd} VND',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${store.orderCount} đơn hàng'),
                            const SizedBox(height: 12),
                            Text('Tiền mặt: ${store.cashVnd} VND'),
                            Text('Chuyển khoản: ${store.transferVnd} VND'),
                            Text('Công nợ: ${store.debtVnd} VND'),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _openStockOnHand,
                      child: const Text('Xem tồn hiện tại'),
                    ),
                  ),
                  if (widget.database != null &&
                      widget.shiftRepository != null)
                    Center(
                      child: TextButton(
                        onPressed: _openReturn,
                        child: const Text('Đổi trả trong ngày'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
