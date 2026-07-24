import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SuppliersRepository {
  SuppliersRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/suppliers');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String? phone,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/suppliers',
      data: {'name': name, 'phone': ?phone},
    );
    return res.data ?? {};
  }

  Future<List<Map<String, dynamic>>> payables(String supplierId) async {
    final res = await _dio.get<List<dynamic>>('/suppliers/$supplierId/payables');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> pay({
    required String supplierId,
    required String storeId,
    required int amountVnd,
    required String channel,
  }) async {
    await _dio.post<void>(
      '/suppliers/$supplierId/payments',
      data: {
        'storeId': storeId,
        'amountVnd': amountVnd,
        'channel': channel,
      },
    );
  }
}

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final SuppliersRepository repository;
  final String storeId;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _addSupplier() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm NCC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'SĐT'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    await widget.repository.create(
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
    );
    await _reload();
  }

  Future<void> _pay(Map<String, dynamic> supplier) async {
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thanh toán ${supplier['name']}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chi'),
          ),
        ],
      ),
    );
    final amount = int.tryParse(amountCtrl.text.trim());
    if (ok != true || amount == null || amount <= 0) return;
    await widget.repository.pay(
      supplierId: supplier['id'] as String,
      storeId: widget.storeId,
      amountVnd: amount,
      channel: 'cash',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ghi thanh toán NCC')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công nợ NCC'),
        actions: [
          IconButton(onPressed: _addSupplier, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final s = _items[i];
                      return ListTile(
                        title: Text('${s['name']}'),
                        subtitle: Text(s['phone']?.toString() ?? ''),
                        trailing: TextButton(
                          onPressed: () => _pay(s),
                          child: const Text('Thanh toán'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
