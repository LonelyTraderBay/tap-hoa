import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../data/local/database.dart';

class EInvoiceRepository {
  EInvoiceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> issue({
    required String saleId,
    String? buyerTaxCode,
    String? templateCode,
    String? serial,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/einvoices/issue',
      data: {
        'saleId': saleId,
        'buyerTaxCode': ?buyerTaxCode,
        'templateCode': ?templateCode,
        'serial': ?serial,
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>?> bySale(String saleId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/einvoices/by-sale/$saleId',
      );
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

class EInvoiceIssuePage extends StatefulWidget {
  const EInvoiceIssuePage({
    super.key,
    required this.repository,
    required this.database,
    required this.storeId,
  });

  final EInvoiceRepository repository;
  final AppDatabase database;
  final String storeId;

  @override
  State<EInvoiceIssuePage> createState() => _EInvoiceIssuePageState();
}

class _EInvoiceIssuePageState extends State<EInvoiceIssuePage> {
  List<SalesLocalData> _sales = [];
  SalesLocalData? _selected;
  final _taxCtrl = TextEditingController();
  final _templateCtrl = TextEditingController(text: '1');
  final _serialCtrl = TextEditingController(text: 'C25TAA');
  String? _error;
  String? _result;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _templateCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
      final startIct = DateTime.utc(now.year, now.month, now.day);
      final start = startIct.subtract(const Duration(hours: 7));
      final end = start.add(const Duration(days: 1));
      final rows = await (widget.database.select(widget.database.salesLocal)
            ..where((t) => t.storeId.equals(widget.storeId))
            ..orderBy([(t) => OrderingTerm.desc(t.clientCreatedAt)]))
          .get();
      final syncedToday = rows
          .where(
            (s) =>
                s.syncedAt != null &&
                !s.clientCreatedAt.isBefore(start) &&
                s.clientCreatedAt.isBefore(end),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _sales = syncedToday;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _issue() async {
    final sale = _selected;
    if (sale == null) {
      setState(() => _error = 'Chọn đơn đã sync');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final issued = await widget.repository.issue(
        saleId: sale.id,
        buyerTaxCode: _taxCtrl.text.trim().isEmpty ? null : _taxCtrl.text.trim(),
        templateCode:
            _templateCtrl.text.trim().isEmpty ? null : _templateCtrl.text.trim(),
        serial: _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result =
            'HĐ ${issued['invoiceNumber']} · ${issued['status']} · ${issued['provider']}';
        _busy = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      setState(() {
        _error = code == 404
            ? 'Đơn chưa có trên server (chưa sync)'
            : 'Xuất HĐ thất bại: ${e.message}';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất HĐĐT'),
        actions: [
          IconButton(onPressed: _loadSales, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Chọn đơn đã sync trong ngày (ICT). Provider theo cấu hình server (stub hoặc HTTP gateway).',
                ),
                const SizedBox(height: 12),
                if (_sales.isEmpty)
                  const Text('Không có đơn đã sync hôm nay.')
                else
                  ..._sales.map(
                    (s) => ListTile(
                      selected: _selected?.id == s.id,
                      onTap: () => setState(() => _selected = s),
                      title: Text('${s.totalVnd} VND'),
                      subtitle: Text(
                        '${s.id.substring(0, 8)}… · ${s.paymentMethod}',
                      ),
                      trailing: _selected?.id == s.id
                          ? const Icon(Icons.check_circle)
                          : null,
                    ),
                  ),
                TextField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(labelText: 'MST khách'),
                ),
                TextField(
                  controller: _templateCtrl,
                  decoration: const InputDecoration(labelText: 'Mẫu số'),
                ),
                TextField(
                  controller: _serialCtrl,
                  decoration: const InputDecoration(labelText: 'Ký hiệu'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _issue,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xuất hóa đơn'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Text(_result!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ],
            ),
    );
  }
}
