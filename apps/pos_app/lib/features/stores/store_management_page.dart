import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';

class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key, required this.db, required this.dio});

  final AppDatabase db;
  final Dio dio;

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final response = await widget.dio.get<List<dynamic>>('/stores');
      final stores = (response.data ?? []).cast<Map<String, dynamic>>();
      for (final store in stores) {
        await upsertStoreLocal(widget.db, store);
      }
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được danh sách cửa hàng (cần online)';
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Map<String, dynamic>? store]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            StoreEditPage(db: widget.db, dio: widget.dio, store: store),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Thêm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
                for (final store in _stores)
                  Card(
                    child: ListTile(
                      title: Text('${store['code']} · ${store['name']}'),
                      subtitle: Text(
                        _thresholdLabel(store['largeDebtThresholdVnd'] as int?),
                      ),
                      trailing: IconButton(
                        onPressed: () => _openForm(store),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Sửa',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class StoreEditPage extends StatefulWidget {
  const StoreEditPage({
    super.key,
    required this.db,
    required this.dio,
    this.store,
  });

  final AppDatabase db;
  final Dio dio;
  final Map<String, dynamic>? store;

  @override
  State<StoreEditPage> createState() => _StoreEditPageState();
}

class _StoreEditPageState extends State<StoreEditPage> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _overdueController;
  late final TextEditingController _largeDebtController;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    _codeController = TextEditingController(text: store?['code'] as String?);
    _nameController = TextEditingController(text: store?['name'] as String?);
    _overdueController = TextEditingController(
      text: '${store?['debtOverdueDays'] as int? ?? 30}',
    );
    _largeDebtController = TextEditingController(
      text: '${store?['largeDebtThresholdVnd'] as int? ?? ''}',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _overdueController.dispose();
    _largeDebtController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final overdueDays = int.tryParse(_overdueController.text.trim());
    final thresholdText = _largeDebtController.text.trim();
    final threshold = thresholdText.isEmpty
        ? null
        : int.tryParse(thresholdText);

    if (code.isEmpty || code.length > 32) {
      setState(() => _error = 'Mã cửa hàng phải dài 1..32 ký tự');
      return;
    }
    if (name.isEmpty || name.length > 120) {
      setState(() => _error = 'Tên cửa hàng phải dài 1..120 ký tự');
      return;
    }
    if (overdueDays == null || overdueDays < 1) {
      setState(() => _error = 'Số ngày quá hạn phải là số nguyên dương');
      return;
    }
    if (thresholdText.isNotEmpty && (threshold == null || threshold <= 0)) {
      setState(() => _error = 'Ngưỡng nợ lớn phải là số dương hoặc để trống');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final data = {
      'code': code,
      'name': name,
      'debtOverdueDays': overdueDays,
      'largeDebtThresholdVnd': threshold,
    };

    try {
      final response = _isEdit
          ? await widget.dio.patch<Map<String, dynamic>>(
              '/stores/${widget.store!['id']}',
              data: data,
            )
          : await widget.dio.post<Map<String, dynamic>>('/stores', data: data);
      final saved = response.data;
      if (saved != null) {
        await upsertStoreLocal(widget.db, saved);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Đã sửa cửa hàng' : 'Đã thêm cửa hàng'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại (kiểm tra mã trùng hoặc kết nối)');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa cửa hàng' : 'Thêm cửa hàng')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Mã cửa hàng'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _overdueController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nợ quá hạn sau X ngày',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _largeDebtController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Ngưỡng push nợ lớn (VND, trống = tắt)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> upsertStoreLocal(
  AppDatabase db,
  Map<String, dynamic> store,
) async {
  final updatedAtText = store['updatedAt'] as String?;
  await db
      .into(db.storesLocal)
      .insertOnConflictUpdate(
        StoresLocalCompanion.insert(
          id: store['id'] as String,
          code: store['code'] as String,
          name: store['name'] as String,
          active: Value(store['active'] as bool? ?? true),
          debtOverdueDays: Value(store['debtOverdueDays'] as int? ?? 30),
          largeDebtThresholdVnd: Value(store['largeDebtThresholdVnd'] as int?),
          updatedAt: updatedAtText == null
              ? DateTime.now().toUtc()
              : DateTime.parse(updatedAtText),
        ),
      );
}

String _thresholdLabel(int? thresholdVnd) {
  if (thresholdVnd == null) {
    return 'Push nợ lớn: tắt';
  }
  return 'Push nợ lớn từ $thresholdVnd VND';
}
