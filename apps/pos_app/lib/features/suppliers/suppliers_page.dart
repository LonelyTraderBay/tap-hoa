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
    final res =
        await _dio.get<List<dynamic>>('/suppliers/$supplierId/payables');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> bankAccounts() async {
    final res = await _dio.get<List<dynamic>>('/suppliers/bank-accounts');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBankAccount({
    required String name,
    String? bankName,
    String? accountNo,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/suppliers/bank-accounts',
      data: {
        'name': name,
        'bankName': ?bankName,
        'accountNo': ?accountNo,
      },
    );
    return res.data ?? {};
  }

  Future<void> pay({
    required String supplierId,
    required String storeId,
    required int amountVnd,
    required String channel,
    String? bankAccountId,
  }) async {
    await _dio.post<void>(
      '/suppliers/$supplierId/payments',
      data: {
        'storeId': storeId,
        'amountVnd': amountVnd,
        'channel': channel,
        'bankAccountId': ?bankAccountId,
      },
    );
  }

  Future<Map<String, dynamic>> createReturn({
    required String supplierId,
    required String storeId,
    required String productId,
    required String qty,
    required int unitCostVnd,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/suppliers/$supplierId/returns',
      data: {
        'storeId': storeId,
        'lines': [
          {
            'productId': productId,
            'qty': qty,
            'unitCostVnd': unitCostVnd,
          },
        ],
      },
    );
    return res.data ?? {};
  }
}

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    required this.repository,
    required this.storeId,
    this.isOwner = false,
  });

  final SuppliersRepository repository;
  final String storeId;
  final bool isOwner;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _banks = [];
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
      final banks = await widget.repository.bankAccounts();
      if (!mounted) return;
      setState(() {
        _items = items;
        _banks = banks;
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

  Future<void> _addBank() async {
    final nameCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final noCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm tài khoản NH'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            TextField(
              controller: bankCtrl,
              decoration: const InputDecoration(labelText: 'Ngân hàng'),
            ),
            TextField(
              controller: noCtrl,
              decoration: const InputDecoration(labelText: 'Số TK'),
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
    await widget.repository.createBankAccount(
      name: nameCtrl.text.trim(),
      bankName: bankCtrl.text.trim().isEmpty ? null : bankCtrl.text.trim(),
      accountNo: noCtrl.text.trim().isEmpty ? null : noCtrl.text.trim(),
    );
    await _reload();
  }

  Future<void> _pay(Map<String, dynamic> supplier) async {
    final amountCtrl = TextEditingController();
    var channel = 'cash';
    String? bankId = _banks.isEmpty ? null : _banks.first['id'] as String?;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Thanh toán ${supplier['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('Tiền mặt')),
                  ButtonSegment(value: 'transfer', label: Text('CK')),
                ],
                selected: {channel},
                onSelectionChanged: (v) =>
                    setLocal(() => channel = v.first),
              ),
              if (channel == 'transfer') ...[
                const SizedBox(height: 8),
                if (_banks.isEmpty)
                  const Text('Chưa có TK NH — thêm trước khi chi CK')
                else
                  ..._banks.map(
                    (b) => ListTile(
                      dense: true,
                      selected: bankId == b['id'],
                      title: Text('${b['name']}'),
                      onTap: () => setLocal(() => bankId = b['id'] as String),
                    ),
                  ),
              ],
            ],
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
      ),
    );
    final amount = int.tryParse(amountCtrl.text.trim());
    if (ok != true || amount == null || amount <= 0) return;
    if (channel == 'transfer' && (bankId == null || bankId!.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn tài khoản ngân hàng')),
      );
      return;
    }
    await widget.repository.pay(
      supplierId: supplier['id'] as String,
      storeId: widget.storeId,
      amountVnd: amount,
      channel: channel,
      bankAccountId: channel == 'transfer' ? bankId : null,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã ghi thanh toán NCC')),
    );
  }

  Future<void> _returnGoods(Map<String, dynamic> supplier) async {
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Trả hàng ${supplier['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productCtrl,
              decoration: const InputDecoration(labelText: 'Product ID'),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Số lượng'),
            ),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn giá gross (VND, gồm VAT)',
              ),
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
            child: const Text('Trả'),
          ),
        ],
      ),
    );
    final cost = int.tryParse(costCtrl.text.trim());
    if (ok != true ||
        productCtrl.text.trim().isEmpty ||
        qtyCtrl.text.trim().isEmpty ||
        cost == null ||
        cost < 0) {
      return;
    }
    try {
      final res = await widget.repository.createReturn(
        supplierId: supplier['id'] as String,
        storeId: widget.storeId,
        productId: productCtrl.text.trim(),
        qty: qtyCtrl.text.trim(),
        unitCostVnd: cost,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã trả hàng · ${res['amountVnd']} VND')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trả hàng thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công nợ NCC'),
        actions: [
          if (widget.isOwner)
            IconButton(
              tooltip: 'Thêm TK NH',
              onPressed: _addBank,
              icon: const Icon(Icons.account_balance_outlined),
            ),
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
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => _returnGoods(s),
                              child: const Text('Trả hàng'),
                            ),
                            TextButton(
                              onPressed: () => _pay(s),
                              child: const Text('Thanh toán'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
