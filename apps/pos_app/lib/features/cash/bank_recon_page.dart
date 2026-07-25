import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class BankReconRepository {
  BankReconRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> summary({
    required String storeId,
    required String periodYm,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/bank-recon',
      queryParameters: {'storeId': storeId, 'periodYm': periodYm},
    );
    return res.data ?? {};
  }

  Future<void> importCsv({
    required String storeId,
    required String periodYm,
    required String csv,
  }) async {
    await _dio.post<void>(
      '/reports/bank-recon/import',
      data: {'storeId': storeId, 'periodYm': periodYm, 'csv': csv},
    );
  }

  Future<void> lock({
    required String storeId,
    required String periodYm,
  }) async {
    await _dio.post<void>(
      '/reports/bank-recon/lock',
      data: {'storeId': storeId, 'periodYm': periodYm},
    );
  }
}

class BankReconPage extends StatefulWidget {
  const BankReconPage({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final BankReconRepository repository;
  final String storeId;

  @override
  State<BankReconPage> createState() => _BankReconPageState();
}

class _BankReconPageState extends State<BankReconPage> {
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
      final data = await widget.repository.summary(
        storeId: widget.storeId,
        periodYm: _periodYm,
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

  Future<void> _import() async {
    final ctrl = TextEditingController(
      text: 'date,amountVnd,memo\n$_periodYm-01,0,mau',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import sao kê CSV'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'date,amountVnd,memo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repository.importCsv(
        storeId: widget.storeId,
        periodYm: _periodYm,
        csv: ctrl.text,
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import thất bại: $e')),
      );
    }
  }

  Future<void> _lock() async {
    try {
      await widget.repository.lock(
        storeId: widget.storeId,
        periodYm: _periodYm,
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã khóa đối chiếu $_periodYm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khóa thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đối chiếu CK $_periodYm'),
        actions: [
          IconButton(
            tooltip: 'Import CSV',
            onPressed: _import,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'Khóa kỳ',
            onPressed: _lock,
            icon: const Icon(Icons.lock_outline),
          ),
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
                      title: const Text('Sổ (book)'),
                      trailing: Text('${_data?['bookTotalVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Sao kê'),
                      trailing: Text('${_data?['statementTotalVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Chênh lệch'),
                      trailing: Text('${_data?['varianceVnd'] ?? 0}'),
                    ),
                    ListTile(
                      title: const Text('Khớp'),
                      subtitle: Text(
                        'matched ${_data?['matchedCount'] ?? 0} · '
                        'book lệch ${_data?['unmatchedBookCount'] ?? 0} · '
                        'sao kê lệch ${_data?['unmatchedStatementCount'] ?? 0}',
                      ),
                      trailing: Text(
                        (_data?['locked'] == true) ? 'Đã khóa' : 'Mở',
                      ),
                    ),
                  ],
                ),
    );
  }
}
