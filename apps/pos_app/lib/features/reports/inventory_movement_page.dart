import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shifts/shift_repository.dart';
import 'inventory_movement_repository.dart';

class InventoryMovementPage extends StatefulWidget {
  const InventoryMovementPage({
    super.key,
    required this.repository,
    required this.storeId,
    required this.role,
    this.stores,
  });

  final InventoryMovementRepository repository;
  final String storeId;
  final String role;
  final List<StoreOption>? stores;

  @override
  State<InventoryMovementPage> createState() => _InventoryMovementPageState();
}

class _InventoryMovementPageState extends State<InventoryMovementPage> {
  late String _selectedStoreId;
  late String _periodYm;
  InventoryMovementReport? _report;
  bool _isLoading = true;
  String? _message;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.storeId;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _periodYm = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadReport();
  }

  bool get _canPickStore =>
      widget.role == 'owner' &&
      widget.stores != null &&
      widget.stores!.isNotEmpty;

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final report = await widget.repository.fetch(
        storeId: _selectedStoreId,
        periodYm: _periodYm,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được báo cáo nhập-xuất-tồn';
        _isLoading = false;
      });
    }
  }

  void _onStoreChanged(String? storeId) {
    if (storeId == null || storeId == _selectedStoreId) {
      return;
    }
    setState(() => _selectedStoreId = storeId);
    _loadReport();
  }

  Future<void> _onPeriodSubmitted(String value) async {
    final next = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(next)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kỳ phải có dạng YYYY-MM')));
      return;
    }
    if (next == _periodYm) return;
    setState(() => _periodYm = next);
    await _loadReport();
  }

  Future<void> _exportCsv() async {
    String csv;
    try {
      csv = await widget.repository.fetchCsv(
        storeId: _selectedStoreId,
        periodYm: _periodYm,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xuất CSV thất bại: $e')));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('CSV $_periodYm'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv.isEmpty ? '(trống)' : csv),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  String _formatByDocType(Map<String, double> byDocType) {
    if (byDocType.isEmpty) return '—';
    return byDocType.entries
        .map((e) => '${e.key} ${_formatQty(e.value)}')
        .join(', ');
  }

  List<InventoryMovementItem> _filtered(List<InventoryMovementItem> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              '${item.name} ${item.sku}'.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;
    final filtered = report == null
        ? const <InventoryMovementItem>[]
        : _filtered(report.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập-xuất-tồn theo kỳ'),
        actions: [
          IconButton(
            onPressed: _isLoading || report == null ? null : _exportCsv,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất CSV',
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
                  Row(
                    children: [
                      if (_canPickStore)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStoreId,
                            decoration: const InputDecoration(
                              labelText: 'Cửa hàng',
                            ),
                            items: [
                              for (final store in widget.stores!)
                                DropdownMenuItem(
                                  value: store.id,
                                  child: Text(
                                    '${store.code} — ${store.name}',
                                  ),
                                ),
                            ],
                            onChanged: _onStoreChanged,
                          ),
                        ),
                      if (_canPickStore) const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_periodYm),
                          initialValue: _periodYm,
                          decoration: const InputDecoration(
                            labelText: 'Kỳ (YYYY-MM)',
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: _onPeriodSubmitted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tìm tên hoặc SKU',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Không có sản phẩm phù hợp',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  else
                    ...filtered.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.sku} · ${item.unit}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Đầu kỳ: ${_formatQty(item.openingQty)} · '
                                'Nhập: ${_formatQty(item.inQty)} · '
                                'Xuất: ${_formatQty(item.outQty)} · '
                                'Cuối kỳ: ${_formatQty(item.closingQty)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhập theo loại: ${_formatByDocType(item.inByDocType)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Xuất theo loại: ${_formatByDocType(item.outByDocType)}',
                                style: theme.textTheme.bodySmall,
                              ),
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
