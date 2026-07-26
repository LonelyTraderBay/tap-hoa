import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApReconRepository {
  ApReconRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> summary({
    required String storeId,
    required String supplierId,
    required String periodYm,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/ap-recon',
      queryParameters: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
      },
    );
    return res.data ?? {};
  }

  Future<void> importCsv({
    required String storeId,
    required String supplierId,
    required String periodYm,
    required String csv,
  }) async {
    await _dio.post<void>(
      '/reports/ap-recon/import',
      data: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
        'csv': csv,
      },
    );
  }

  Future<void> autoMatch({
    required String storeId,
    required String supplierId,
    required String periodYm,
  }) async {
    await _dio.post<void>(
      '/reports/ap-recon/auto-match',
      data: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
      },
    );
  }

  Future<void> match({
    required String storeId,
    required String supplierId,
    required String periodYm,
    required String statementId,
    required String bookRef,
    int? matchVersion,
  }) async {
    await _dio.post<void>(
      '/reports/ap-recon/match',
      data: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
        'statementId': statementId,
        'bookRef': bookRef,
        'matchVersion': ?matchVersion,
      },
    );
  }

  Future<void> unmatch({
    required String storeId,
    required String supplierId,
    required String periodYm,
    required String statementId,
    int? matchVersion,
  }) async {
    await _dio.post<void>(
      '/reports/ap-recon/unmatch',
      data: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
        'statementId': statementId,
        'matchVersion': ?matchVersion,
      },
    );
  }

  Future<void> lock({
    required String storeId,
    required String supplierId,
    required String periodYm,
  }) async {
    await _dio.post<void>(
      '/reports/ap-recon/lock',
      data: {
        'storeId': storeId,
        'supplierId': supplierId,
        'periodYm': periodYm,
      },
    );
  }
}

class ApReconPage extends StatefulWidget {
  const ApReconPage({
    super.key,
    required this.repository,
    required this.storeId,
    required this.supplierId,
    required this.supplierName,
  });

  final ApReconRepository repository;
  final String storeId;
  final String supplierId;
  final String supplierName;

  @override
  State<ApReconPage> createState() => _ApReconPageState();
}

class _ApReconPageState extends State<ApReconPage> {
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
        supplierId: widget.supplierId,
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
    final ctrl = TextEditingController(text: 'date,amountVnd,memo\n');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán CSV sao kê NCC'),
        content: TextField(
          controller: ctrl,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText:
                'date,amountVnd,memo\n2026-07-15,120000,PN\n2026-07-15,-40000,TT',
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
        supplierId: widget.supplierId,
        periodYm: _periodYm,
        csv: ctrl.text,
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import thất bại: $e')));
    }
  }

  Future<void> _autoMatch() async {
    try {
      await widget.repository.autoMatch(
        storeId: widget.storeId,
        supplierId: widget.supplierId,
        periodYm: _periodYm,
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auto-match thất bại: $e')));
    }
  }

  Future<void> _lock() async {
    try {
      await widget.repository.lock(
        storeId: widget.storeId,
        supplierId: widget.supplierId,
        periodYm: _periodYm,
      );
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã khóa đối chiếu NCC $_periodYm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Khóa thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statements = ((_data?['statements'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final unmatchedBook = ((_data?['unmatchedBook'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final matched = ((_data?['matched'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final locked = _data?['locked'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đối chiếu NCC ${widget.supplierName} $_periodYm'),
        actions: [
          IconButton(
            tooltip: 'Import CSV',
            onPressed: locked ? null : _import,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'Auto-match',
            onPressed: locked ? null : _autoMatch,
            icon: const Icon(Icons.join_inner),
          ),
          IconButton(
            tooltip: 'Khóa kỳ',
            onPressed: locked ? null : _lock,
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
                  title: const Text('Sổ AP'),
                  trailing: Text('${_data?['bookTotalVnd'] ?? 0}'),
                ),
                ListTile(
                  title: const Text('Sao kê NCC'),
                  trailing: Text('${_data?['statementTotalVnd'] ?? 0}'),
                ),
                ListTile(
                  title: const Text('Chênh lệch'),
                  trailing: Text('${_data?['varianceVnd'] ?? 0}'),
                ),
                ListTile(
                  title: Text(locked ? 'Đã khóa' : 'Đang mở'),
                  subtitle: Text(
                    'matched ${_data?['matchedCount'] ?? 0} · '
                    'gợi ý ${_data?['suggestedMatchCount'] ?? 0} · '
                    'book lệch ${_data?['unmatchedBookCount'] ?? 0} · '
                    'sao kê lệch ${_data?['unmatchedStatementCount'] ?? 0}',
                  ),
                ),
                const Divider(),
                const ListTile(title: Text('Đã khớp / gợi ý')),
                ...matched.map((m) {
                  final suggested = m['suggested'] == true;
                  return ListTile(
                    dense: true,
                    title: Text('${m['bookRef']} ↔ ${m['amountVnd']}'),
                    subtitle: Text(suggested ? 'Gợi ý (chưa lưu)' : 'Đã lưu'),
                    trailing: locked
                        ? null
                        : suggested
                        ? IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await widget.repository.match(
                                  storeId: widget.storeId,
                                  supplierId: widget.supplierId,
                                  periodYm: _periodYm,
                                  statementId: m['statementId'] as String,
                                  bookRef: m['bookRef'] as String,
                                );
                                await _reload();
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.link_off),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await widget.repository.unmatch(
                                  storeId: widget.storeId,
                                  supplierId: widget.supplierId,
                                  periodYm: _periodYm,
                                  statementId: m['statementId'] as String,
                                );
                                await _reload();
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            },
                          ),
                  );
                }),
                const Divider(),
                const ListTile(title: Text('Sao kê NCC')),
                ...statements.map(
                  (s) => ListTile(
                    dense: true,
                    title: Text('${s['amountVnd']} · ${s['memo'] ?? ''}'),
                    subtitle: Text(
                      '${s['bookedAt']} · ${s['matchedRef'] ?? 'chưa khớp'}',
                    ),
                  ),
                ),
                const Divider(),
                const ListTile(title: Text('Book AP chưa khớp')),
                ...unmatchedBook.map(
                  (b) => ListTile(
                    dense: true,
                    title: Text('${b['ref']} · ${b['amountVnd']}'),
                    subtitle: Text('${b['kind']} · ${b['at']}'),
                  ),
                ),
              ],
            ),
    );
  }
}
