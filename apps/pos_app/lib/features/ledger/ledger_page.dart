import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'vat_settings_sheet.dart';

/// Read-only ledger views for owner (server-of-truth).
class LedgerRepository {
  LedgerRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Dio get dio => _dio;

  Future<List<Map<String, dynamic>>> journal({
    required String from,
    required String to,
    String? storeId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/ledger/journal',
      queryParameters: {
        'from': from,
        'to': to,
        'storeId': ?storeId,
      },
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> trialBalance(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/ledger/trial-balance',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
    );
    return res.data ?? {};
  }

  Future<void> lockPeriod(String periodYm) async {
    await _dio.post<void>(
      '/ledger/period-locks',
      data: {'periodYm': periodYm},
    );
  }

  Future<List<Map<String, dynamic>>> periodLocks() async {
    final res = await _dio.get<List<dynamic>>('/ledger/period-locks');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> periodPnl(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/pnl',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
    );
    return res.data ?? {};
  }

  Future<String> periodExportCsv(String periodYm, {String? storeId}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/export.csv',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
    );
    return (res.data?['csv'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> periodVat(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/vat',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
    );
    return res.data ?? {};
  }

  Future<List<int>> periodExportXlsx(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<List<int>>(
      '/reports/period/export.xlsx',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<List<int>> periodExportPdf(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<List<int>>(
      '/reports/period/export.pdf',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<String> vatDeclarationCsv(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/vat-declaration.csv',
      queryParameters: {
        'periodYm': periodYm,
        'storeId': ?storeId,
      },
    );
    return (res.data?['csv'] as String?) ?? '';
  }
}

class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({
    super.key,
    required this.repository,
    required this.isOwner,
    this.storeId,
  });

  final LedgerRepository repository;
  final bool isOwner;
  /// When set, period reports are store-scoped; null = owner aggregate.
  final String? storeId;

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> {
  late String _periodYm;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _tbRows = [];
  List<Map<String, dynamic>> _locks = [];
  Map<String, dynamic>? _pnl;
  Map<String, dynamic>? _vat;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _periodYm =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
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
      final entries = await widget.repository.journal(
        from: from.toIso8601String(),
        to: to.toIso8601String(),
        storeId: widget.storeId,
      );
      final tb = await widget.repository.trialBalance(
        _periodYm,
        storeId: widget.storeId,
      );
      final pnl = await widget.repository.periodPnl(
        _periodYm,
        storeId: widget.storeId,
      );
      final vat = await widget.repository.periodVat(
        _periodYm,
        storeId: widget.storeId,
      );
      final locks = await widget.repository.periodLocks();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _tbRows = ((tb['rows'] as List?) ?? []).cast<Map<String, dynamic>>();
        _pnl = pnl;
        _vat = vat;
        _locks = locks;
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

  Future<void> _lock() async {
    try {
      await widget.repository.lockPeriod(_periodYm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã khóa sổ $_periodYm')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khóa sổ thất bại: $e')),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      final csv = await widget.repository.periodExportCsv(
        _periodYm,
        storeId: widget.storeId,
      );
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất CSV thất bại: $e')),
      );
    }
  }

  Future<void> _exportExcel() async {
    try {
      final bytes = await widget.repository.periodExportXlsx(
        _periodYm,
        storeId: widget.storeId,
      );
      if (bytes.isEmpty) {
        throw Exception('empty_xlsx');
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}${Platform.pathSeparator}period-$_periodYm.xlsx';
      await File(path).writeAsBytes(bytes, flush: true);
      await Clipboard.setData(ClipboardData(text: path));
      if (Platform.isWindows) {
        await Process.start('explorer.exe', ['/select,', path]);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải Excel: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất Excel thất bại: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    try {
      final bytes = await widget.repository.periodExportPdf(
        _periodYm,
        storeId: widget.storeId,
      );
      if (bytes.isEmpty) throw Exception('empty_pdf');
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}${Platform.pathSeparator}period-$_periodYm.pdf';
      await File(path).writeAsBytes(bytes, flush: true);
      await Clipboard.setData(ClipboardData(text: path));
      if (Platform.isWindows) {
        await Process.start('explorer.exe', ['/select,', path]);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải PDF: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất PDF thất bại: $e')),
      );
    }
  }

  Future<void> _exportVatDeclaration() async {
    try {
      final csv = await widget.repository.vatDeclarationCsv(
        _periodYm,
        storeId: widget.storeId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Hỗ trợ kê khai GTGT $_periodYm'),
          content: SingleChildScrollView(child: SelectableText(csv)),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất hỗ trợ kê khai thất bại: $e')),
      );
    }
  }

  bool get _periodLocked =>
      _locks.any((l) => l['periodYm']?.toString() == _periodYm);

  @override
  Widget build(BuildContext context) {
    final lockHint = _periodLocked
        ? 'Kỳ $_periodYm đã khóa'
        : (_locks.isEmpty
            ? 'Chưa khóa kỳ nào'
            : 'Đã khóa: ${_locks.take(3).map((l) => l['periodYm']).join(', ')}');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.storeId == null
                    ? 'Sổ kế toán (tổng hợp)'
                    : 'Sổ kế toán (cửa hàng)',
              ),
              Text(
                '$_periodYm · $lockHint',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nhật ký'),
              Tab(text: 'CĐPS'),
              Tab(text: 'KQKD'),
              Tab(text: 'VAT'),
            ],
          ),
          actions: [
            if (widget.isOwner)
              IconButton(
                tooltip: 'Cấu hình GTGT',
                onPressed: () => showVatSettingsSheet(
                  context,
                  dio: widget.repository.dio,
                  role: 'owner',
                ),
                icon: const Icon(Icons.percent_outlined),
              ),
            IconButton(
              tooltip: 'Xuất CSV',
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_outlined),
            ),
            IconButton(
              tooltip: 'Xuất Excel',
              onPressed: _exportExcel,
              icon: const Icon(Icons.table_view_outlined),
            ),
            IconButton(
              tooltip: 'Xuất PDF',
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Hỗ trợ kê khai GTGT',
              onPressed: _exportVatDeclaration,
              icon: const Icon(Icons.receipt_outlined),
            ),
            if (widget.isOwner)
              IconButton(
                tooltip: 'Khóa sổ tháng',
                onPressed: _lock,
                icon: const Icon(Icons.lock_outline),
              ),
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final e = _entries[i];
                          return ListTile(
                            title: Text('${e['sourceType']} · ${e['sourceId']}'),
                            subtitle: Text(
                              '${e['periodYm']} · ${e['postedAt']}',
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: _tbRows.length,
                        itemBuilder: (context, i) {
                          final r = _tbRows[i];
                          return ListTile(
                            title: Text('${r['accountCode']} ${r['name']}'),
                            subtitle: Text(
                              'Nợ ${r['debitVnd']} · Có ${r['creditVnd']}',
                            ),
                            trailing: Text('${r['balanceVnd']}'),
                          );
                        },
                      ),
                      ListView(
                        children: [
                          ListTile(
                            title: const Text('Doanh thu'),
                            trailing: Text('${_pnl?['revenueVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('Giá vốn'),
                            trailing: Text('${_pnl?['cogsVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('Lãi gộp'),
                            trailing: Text('${_pnl?['grossProfitVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('Chi phí'),
                            trailing:
                                Text('${_pnl?['operatingExpenseVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('Lãi ròng'),
                            trailing: Text('${_pnl?['netIncomeVnd'] ?? 0}'),
                          ),
                        ],
                      ),
                      ListView(
                        children: [
                          ListTile(
                            title: const Text('GTGT đầu ra (3331)'),
                            trailing: Text('${_vat?['outputVatVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('GTGT đầu vào (1331)'),
                            trailing: Text('${_vat?['inputVatVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('GTGT phải nộp'),
                            trailing: Text('${_vat?['netVatVnd'] ?? 0}'),
                          ),
                          ListTile(
                            title: const Text('Doanh thu chịu thuế (511)'),
                            trailing: Text('${_vat?['revenueBaseVnd'] ?? 0}'),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
