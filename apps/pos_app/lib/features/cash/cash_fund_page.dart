import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CashFundRepository {
  CashFundRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> summary({
    required String storeId,
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/cash-fund',
      queryParameters: {
        'storeId': storeId,
        'from': from,
        'to': to,
      },
    );
    return res.data ?? {};
  }
}

class CashFundPage extends StatefulWidget {
  const CashFundPage({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final CashFundRepository repository;
  final String storeId;

  @override
  State<CashFundPage> createState() => _CashFundPageState();
}

class _CashFundPageState extends State<CashFundPage> {
  late String _periodYm;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _periodYm = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final parts = _periodYm.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final from = DateTime.utc(y, m, 1).subtract(const Duration(hours: 7));
      final to = DateTime.utc(y, m + 1, 1).subtract(const Duration(hours: 7));
      final data = await widget.repository.summary(
        storeId: widget.storeId,
        from: from.toIso8601String(),
        to: to.toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sổ quỹ kỳ $_periodYm'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  children: [
                    ListTile(
                      title: const Text('Tiền mặt bán'),
                      trailing: Text('${_data?['saleCashVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Chuyển khoản bán'),
                      trailing: Text('${_data?['saleTransferVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Phiếu thu'),
                      trailing: Text('${_data?['voucherInVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Phiếu chi'),
                      trailing: Text('${_data?['voucherOutVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Ròng tiền mặt'),
                      trailing: Text(
                        '${_data?['netCashVnd'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
    );
  }
}
