import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showVatSettingsSheet(
  BuildContext context, {
  required Dio dio,
  required String role,
}) async {
  if (role != 'owner' && role != 'store_manager') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉ chủ/quản lý được sửa thuế GTGT')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _VatSettingsSheet(dio: dio),
  );
}

class _VatSettingsSheet extends StatefulWidget {
  const _VatSettingsSheet({required this.dio});

  final Dio dio;

  @override
  State<_VatSettingsSheet> createState() => _VatSettingsSheetState();
}

class _VatSettingsSheetState extends State<_VatSettingsSheet> {
  final _bpsController = TextEditingController(text: '1000');
  List<Map<String, dynamic>> _stores = [];
  String? _storeId;
  bool _vatEnabled = false;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bpsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await widget.dio.get<List<dynamic>>('/stores');
      final stores = (res.data ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      final first = stores.isEmpty ? null : stores.first;
      setState(() {
        _stores = stores;
        _storeId = first?['id'] as String?;
        _vatEnabled = first?['vatEnabled'] as bool? ?? false;
        _bpsController.text =
            '${first?['defaultVatRateBps'] as int? ?? 1000}';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách cửa hàng (cần online)';
        _loading = false;
      });
    }
  }

  void _onStoreChanged(String? id) {
    final store = _stores.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s?['id'] == id,
          orElse: () => null,
        );
    setState(() {
      _storeId = id;
      _vatEnabled = store?['vatEnabled'] as bool? ?? false;
      _bpsController.text = '${store?['defaultVatRateBps'] as int? ?? 1000}';
    });
  }

  Future<void> _save() async {
    final storeId = _storeId;
    if (storeId == null) {
      setState(() => _error = 'Chọn cửa hàng');
      return;
    }
    final bps = int.tryParse(_bpsController.text.trim());
    if (bps == null || bps < 0 || bps > 10000) {
      setState(() => _error = 'Thuế suất bps phải là 0..10000 (1000 = 10%)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.dio.patch<Map<String, dynamic>>(
        '/stores/$storeId/vat',
        data: {'vatEnabled': _vatEnabled, 'defaultVatRateBps': bps},
      );
      final idx = _stores.indexWhere((s) => s['id'] == storeId);
      if (idx >= 0 && res.data != null) {
        _stores[idx] = {..._stores[idx], ...res.data!};
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _vatEnabled
                ? 'Đã bật GTGT ($bps bps) — chỉ chứng từ mới'
                : 'Đã tắt GTGT — journal như cũ',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại (cần online)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thuế GTGT cửa hàng',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Giá bán/nhập đã gồm thuế. Bật muộn không backfill sổ cũ.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_storeId),
                  initialValue: _storeId,
                  items: _stores
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text('${s['code']} · ${s['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: _onStoreChanged,
                  decoration: const InputDecoration(labelText: 'Cửa hàng'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật hạch toán GTGT'),
                  value: _vatEnabled,
                  onChanged: (v) => setState(() => _vatEnabled = v),
                ),
                TextField(
                  controller: _bpsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Thuế suất (bps, 1000 = 10%)',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Lưu'),
                ),
              ],
            ),
    );
  }
}
