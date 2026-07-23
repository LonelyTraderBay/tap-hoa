import 'package:flutter/material.dart';

import 'day_report_repository.dart';

class DayReportPage extends StatefulWidget {
  const DayReportPage({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final DayReportRepository repository;
  final String storeId;

  @override
  State<DayReportPage> createState() => _DayReportPageState();
}

class _DayReportPageState extends State<DayReportPage> {
  DateTime _selectedDate = DateTime.now();
  DayReport? _report;
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
      final report = await widget.repository.fetchDayReport(
        date: _selectedDate,
        storeId: widget.storeId,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
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

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo ngày'),
        actions: [
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
          : report == null
          ? const Center(child: Text('Không có dữ liệu'))
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (report.isOffline)
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
                ],
              ),
            ),
    );
  }
}
