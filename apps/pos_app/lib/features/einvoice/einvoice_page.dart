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

  Future<Map<String, dynamic>> cancel({
    required String invoiceId,
    required String reason,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/einvoices/$invoiceId/cancel',
      data: {'reason': reason},
    );
    return res.data ?? {};
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
  Map<String, dynamic>? _invoice;
  bool _loading = true;
  bool _invoiceLoading = false;
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
      final rows =
          await (widget.database.select(widget.database.salesLocal)
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
        _selected = syncedToday.any((s) => s.id == _selected?.id)
            ? _selected
            : null;
        if (_selected == null) _invoice = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectSale(SalesLocalData sale) async {
    setState(() {
      _selected = sale;
      _invoice = null;
      _invoiceLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final invoice = await widget.repository.bySale(sale.id);
      if (!mounted || _selected?.id != sale.id) return;
      setState(() {
        _invoice = invoice;
        _invoiceLoading = false;
      });
    } catch (e) {
      if (!mounted || _selected?.id != sale.id) return;
      setState(() {
        _error = 'Không tải được trạng thái HĐĐT: $e';
        _invoiceLoading = false;
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
        buyerTaxCode: _taxCtrl.text.trim().isEmpty
            ? null
            : _taxCtrl.text.trim(),
        templateCode: _templateCtrl.text.trim().isEmpty
            ? null
            : _templateCtrl.text.trim(),
        serial: _serialCtrl.text.trim().isEmpty
            ? null
            : _serialCtrl.text.trim(),
      );
      if (!mounted) return;
      final status = issued['status']?.toString() ?? '';
      final pdf = issued['pdfPath']?.toString();
      final xml = issued['xmlPath']?.toString();
      final links = [
        if (pdf != null && pdf.isNotEmpty) 'PDF: $pdf',
        if (xml != null && xml.isNotEmpty) 'XML: $xml',
      ].join(' · ');
      setState(() {
        _invoice = issued;
        if (status == 'pending_sign') {
          _result =
              'Đang chờ ký · ${issued['invoiceNumber']} · ${issued['provider']}'
              '${links.isEmpty ? '' : ' · $links'}';
        } else if (status == 'failed') {
          _error = 'HĐĐT thất bại · ${issued['errorMessage'] ?? 'thử lại'}';
          _result = null;
        } else {
          _result =
              'HĐ ${issued['invoiceNumber']} · $status · ${issued['provider']}'
              '${links.isEmpty ? '' : ' · $links'}';
        }
        _busy = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      setState(() {
        _error = code == 404
            ? 'Đơn chưa có trên server (chưa sync)'
            : 'Xuất HĐ thất bại — có thể thử lại: ${e.message}';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Xuất HĐ thất bại — có thể thử lại: $e';
        _busy = false;
      });
    }
  }

  bool _canCancelInvoice(Map<String, dynamic>? invoice) {
    final status = invoice?['status']?.toString();
    return status == 'issued' || status == 'pending_sign';
  }

  Future<String?> _askCancelReason() async {
    final ctrl = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hủy HĐĐT'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Lý do hủy'),
            minLines: 2,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _cancel() async {
    final invoice = _invoice;
    if (!_canCancelInvoice(invoice)) return;
    final reason = await _askCancelReason();
    if (reason == null) return;
    if (reason.isEmpty) {
      setState(() => _error = 'Nhập lý do hủy HĐĐT');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final cancelled = await widget.repository.cancel(
        invoiceId: invoice!['id'].toString(),
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _invoice = cancelled;
        final invoiceNumber = cancelled['invoiceNumber']?.toString();
        _result =
            'Đã hủy HĐĐT'
            '${invoiceNumber == null || invoiceNumber.isEmpty ? '' : ' · $invoiceNumber'}';
        _busy = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Hủy HĐ thất bại: ${e.message}';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Hủy HĐ thất bại: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    final invoiceStatus = invoice?['status']?.toString();
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
                      onTap: () => _selectSale(s),
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
                if (_invoiceLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ] else if (invoiceStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'HĐĐT hiện tại: $invoiceStatus'
                    '${invoice?['invoiceNumber'] == null ? '' : ' · ${invoice?['invoiceNumber']}'}',
                  ),
                ],
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
                if (_canCancelInvoice(invoice)) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Hủy hóa đơn'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _result!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
    );
  }
}
