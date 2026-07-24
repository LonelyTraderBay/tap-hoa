import 'package:flutter/material.dart';

import '../products/barcode_label.dart';
import '../shifts/shift_repository.dart';
import 'stock_on_hand_repository.dart';

class StockOnHandPage extends StatefulWidget {
  const StockOnHandPage({
    super.key,
    required this.repository,
    required this.storeId,
    required this.role,
    this.stores,
  });

  final StockOnHandRepository repository;
  final String storeId;
  final String role;
  final List<StoreOption>? stores;

  @override
  State<StockOnHandPage> createState() => _StockOnHandPageState();
}

class _StockOnHandPageState extends State<StockOnHandPage> {
  late String _selectedStoreId;
  StockOnHandReport? _report;
  bool _isLoading = true;
  String? _message;
  String _searchQuery = '';
  bool _belowMinOnly = false;
  bool _showZero = false;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.storeId;
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
      final report = await widget.repository.fetch(storeId: _selectedStoreId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được báo cáo tồn';
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

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;
    final filtered = report == null
        ? const <StockOnHandItem>[]
        : applyStockOnHandFilters(
            report.items,
            query: _searchQuery,
            belowMinOnly: _belowMinOnly,
            showZero: _showZero,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Tồn hiện tại')),
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
                  if (_canPickStore)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Cửa hàng',
                        ),
                        items: [
                          for (final store in widget.stores!)
                            DropdownMenuItem(
                              value: store.id,
                              child: Text('${store.code} — ${store.name}'),
                            ),
                        ],
                        onChanged: _onStoreChanged,
                      ),
                    ),
                  Text(
                    formatPriceLabelVnd(report.totalEstimatedValueVnd),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng giá trị tồn ước tính',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tìm tên hoặc SKU',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dưới định mức'),
                    value: _belowMinOnly,
                    onChanged: (value) =>
                        setState(() => _belowMinOnly = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hiện hết'),
                    subtitle: const Text('Bao gồm sản phẩm tồn = 0'),
                    value: _showZero,
                    onChanged: (value) => setState(() => _showZero = value),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Không có tồn phù hợp bộ lọc',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  else
                    ...filtered.map((item) {
                      final highlight = item.belowMin;
                      return Card(
                        color: highlight
                            ? theme.colorScheme.errorContainer.withValues(
                                alpha: 0.35,
                              )
                            : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item.sku} · SL: ${_formatQty(item.qty)}/${item.unit} · '
                            'ĐM: ${_formatQty(item.minQty)} · '
                            '${formatPriceLabelVnd(item.estimatedValueVnd)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
