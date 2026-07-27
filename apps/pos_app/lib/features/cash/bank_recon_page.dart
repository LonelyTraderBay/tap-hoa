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

  Future<void> autoMatch({
    required String storeId,
    required String periodYm,
  }) async {
    await _dio.post<void>(
      '/reports/bank-recon/auto-match',
      data: {'storeId': storeId, 'periodYm': periodYm},
    );
  }

  Future<void> match({
    required String storeId,
    required String periodYm,
    required String statementId,
    required String bookRef,
    int? matchVersion,
  }) async {
    await _dio.post<void>(
      '/reports/bank-recon/match',
      data: {
        'storeId': storeId,
        'periodYm': periodYm,
        'statementId': statementId,
        'bookRef': bookRef,
        'matchVersion': ?matchVersion,
      },
    );
  }

  Future<void> unmatch({
    required String storeId,
    required String periodYm,
    required String statementId,
    int? matchVersion,
  }) async {
    await _dio.post<void>(
      '/reports/bank-recon/unmatch',
      data: {
        'storeId': storeId,
        'periodYm': periodYm,
        'statementId': statementId,
        'matchVersion': ?matchVersion,
      },
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

  /// P2.2: danh mục thu/chi (kèm map TK hiện tại) — dùng cho picker khi tạo
  /// bút toán trực tiếp từ một dòng sao kê chưa khớp.
  Future<List<Map<String, dynamic>>> listCategories() async {
    final res = await _dio.get<List<dynamic>>('/ledger/cash-categories');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  /// P2.2: tạo một CashVoucher (channel=transfer, không gắn ca) trực tiếp
  /// từ dòng sao kê [statementId] chưa khớp, post sổ, rồi khớp luôn — dùng
  /// khi bank báo một khoản (thường là phí NH) chưa từng được ghi ở đâu
  /// trong app, nếu không kỳ đó sẽ không bao giờ khoá được.
  Future<Map<String, dynamic>> createEntry({
    required String storeId,
    required String periodYm,
    required String statementId,
    required String categoryId,
    String? note,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/reports/bank-recon/create-entry',
      data: {
        'storeId': storeId,
        'periodYm': periodYm,
        'statementId': statementId,
        'categoryId': categoryId,
        'note': ?note,
      },
    );
    return res.data ?? {};
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
      text: 'date,amountVnd,memo\n',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán nội dung CSV sao kê'),
        content: TextField(
          controller: ctrl,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'date,amountVnd,memo\n2026-07-15,50000,CK ban',
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

  Future<void> _autoMatch() async {
    try {
      await widget.repository.autoMatch(
        storeId: widget.storeId,
        periodYm: _periodYm,
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-match thất bại: $e')),
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

  /// P2.2: tạo bút toán book-side trực tiếp cho một dòng sao kê [statement]
  /// chưa khớp (khoản bank báo mà app chưa từng ghi ở đâu, vd. phí NH) —
  /// chọn danh mục rồi gọi endpoint tạo+khớp, tái dùng máy match/lock sẵn có.
  Future<void> _createEntry(Map<String, dynamic> statement) async {
    List<Map<String, dynamic>> categories;
    try {
      categories = await widget.repository.listCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được danh mục: $e')));
      return;
    }
    final amount = (statement['amountVnd'] as num).toInt();
    final direction = amount >= 0 ? 'in' : 'out';
    final options = categories
        .where((c) => c['direction'] == direction)
        .toList();
    if (!mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh mục phù hợp chiều này')),
      );
      return;
    }
    String? categoryId = options.first['id'] as String?;
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tạo bút toán từ dòng sao kê'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${statement['amountVnd']} · ${statement['memo'] ?? ''}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: options
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => categoryId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tuỳ chọn)',
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
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || categoryId == null) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.createEntry(
        storeId: widget.storeId,
        periodYm: _periodYm,
        statementId: statement['id'] as String,
        categoryId: categoryId!,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      await _reload();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã tạo bút toán và khớp dòng sao kê')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Tạo bút toán thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statements =
        ((_data?['statements'] as List?) ?? []).cast<Map<String, dynamic>>();
    final unmatchedBook =
        ((_data?['unmatchedBook'] as List?) ?? []).cast<Map<String, dynamic>>();
    final matched =
        ((_data?['matched'] as List?) ?? []).cast<Map<String, dynamic>>();
    final locked = _data?['locked'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đối chiếu CK $_periodYm'),
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
                      title: Text(
                        locked ? 'Đã khóa' : 'Đang mở',
                      ),
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
                        subtitle: Text(
                          suggested ? 'Gợi ý (chưa lưu)' : 'Đã lưu',
                        ),
                        trailing: locked
                            ? null
                            : suggested
                                ? IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      try {
                                        await widget.repository.match(
                                          storeId: widget.storeId,
                                          periodYm: _periodYm,
                                          statementId:
                                              m['statementId'] as String,
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
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      try {
                                        await widget.repository.unmatch(
                                          storeId: widget.storeId,
                                          periodYm: _periodYm,
                                          statementId:
                                              m['statementId'] as String,
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
                    const ListTile(title: Text('Sao kê')),
                    ...statements.map((s) {
                      final unmatched = s['matchedRef'] == null;
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${s['amountVnd']} · ${s['memo'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${s['bookedAt']} · ${s['matchedRef'] ?? 'chưa khớp'}',
                        ),
                        // P2.2: dòng sao kê chưa khớp không có phía "book"
                        // tương ứng (vd. phí NH chưa từng ghi ở đâu) — cho
                        // tạo thẳng một bút toán rồi khớp luôn, thay vì phải
                        // sang màn Sổ thu chi tạo phiếu rồi quay lại khớp tay.
                        trailing: (!locked && unmatched)
                            ? IconButton(
                                tooltip: 'Tạo bút toán từ dòng này',
                                icon: const Icon(Icons.post_add),
                                onPressed: () => _createEntry(s),
                              )
                            : null,
                      );
                    }),
                    const Divider(),
                    const ListTile(title: Text('Book chưa khớp')),
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
