import 'dart:convert';
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

  Map<String, dynamic> _periodQuery(String periodYm, {String? storeId}) => {
    'periodYm': periodYm,
    'storeId': ?storeId,
  };

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
      queryParameters: _periodQuery(periodYm, storeId: storeId),
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> accountLedger({
    required String accountCode,
    required String periodYm,
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/ledger/account-ledger',
      queryParameters: {
        'accountCode': accountCode,
        ..._periodQuery(periodYm, storeId: storeId),
      },
    );
    return res.data ?? {};
  }

  Future<void> lockPeriod(String periodYm) async {
    await _dio.post<void>('/ledger/period-locks', data: {'periodYm': periodYm});
  }

  Future<void> unlockPeriod(String periodYm, String reason) async {
    await _dio.post<void>(
      '/ledger/period-locks/$periodYm/unlock',
      data: {'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> periodLocks() async {
    final res = await _dio.get<List<dynamic>>('/ledger/period-locks');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listAudit({int limit = 50}) async {
    final res = await _dio.get<List<dynamic>>(
      '/ledger/audit',
      queryParameters: {'limit': limit},
    );
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> periodPnl(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/pnl',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
    );
    return res.data ?? {};
  }

  Future<String> periodExportCsv(String periodYm, {String? storeId}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/export.csv',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
    );
    return (res.data?['csv'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> periodVat(
    String periodYm, {
    String? storeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/vat',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
    );
    return res.data ?? {};
  }

  Future<List<int>> periodExportXlsx(String periodYm, {String? storeId}) async {
    final res = await _dio.get<List<int>>(
      '/reports/period/export.xlsx',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<List<int>> periodExportPdf(String periodYm, {String? storeId}) async {
    final res = await _dio.get<List<int>>(
      '/reports/period/export.pdf',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<String> vatDeclarationCsv(String periodYm, {String? storeId}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period/vat-declaration.csv',
      queryParameters: _periodQuery(periodYm, storeId: storeId),
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
  String _accountCode = '111';
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _tbRows = [];
  List<Map<String, dynamic>> _locks = [];
  List<Map<String, dynamic>> _audit = [];
  Map<String, dynamic>? _accountLedger;
  Map<String, dynamic>? _pnl;
  Map<String, dynamic>? _vat;
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
      final entries = await widget.repository.journal(
        from: from.toIso8601String(),
        to: to.toIso8601String(),
        storeId: widget.storeId,
      );
      final tb = await widget.repository.trialBalance(
        _periodYm,
        storeId: widget.storeId,
      );
      final tbRows = ((tb['rows'] as List?) ?? []).cast<Map<String, dynamic>>();
      var accountCode = _accountCode;
      if (!tbRows.any((r) => r['accountCode']?.toString() == accountCode) &&
          tbRows.isNotEmpty) {
        accountCode = tbRows.first['accountCode'].toString();
      }
      final accountLedger = await widget.repository.accountLedger(
        accountCode: accountCode,
        periodYm: _periodYm,
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
      final audit = await widget.repository.listAudit();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _accountCode = accountCode;
        _tbRows = tbRows;
        _accountLedger = accountLedger;
        _pnl = pnl;
        _vat = vat;
        _locks = locks;
        _audit = audit;
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

  Future<void> _changePeriod(String value) async {
    final next = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(next)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kỳ phải có dạng YYYY-MM')));
      return;
    }
    setState(() {
      _periodYm = next;
    });
    await _reload();
  }

  Future<void> _changeAccount(String? value) async {
    if (value == null || value == _accountCode) return;
    setState(() {
      _accountCode = value;
    });
    await _reload();
  }

  Future<void> _unlock(String periodYm) async {
    final reason = await _promptUnlockReason(periodYm);
    if (reason == null) return;
    try {
      await widget.repository.unlockPeriod(periodYm, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã mở khóa kỳ $periodYm')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mở khóa thất bại: $e')));
    }
  }

  Future<String?> _promptUnlockReason(String periodYm) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('Mở khóa kỳ $periodYm'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Lý do',
                errorText: errorText,
              ),
              minLines: 2,
              maxLines: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final trimmed = controller.text.trim();
                  if (trimmed.length < 3) {
                    setDialogState(() {
                      errorText = 'Nhập ít nhất 3 ký tự';
                    });
                    return;
                  }
                  Navigator.pop(ctx, trimmed);
                },
                child: const Text('Mở khóa'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _lock() async {
    try {
      await widget.repository.lockPeriod(_periodYm);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã khóa sổ $_periodYm')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Khóa sổ thất bại: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xuất CSV thất bại: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã tải Excel: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xuất Excel thất bại: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã tải PDF: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xuất PDF thất bại: $e')));
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

  List<String> _auditDetailLines(Map<String, dynamic> row) {
    final detailJson = row['detailJson']?.toString();
    if (detailJson == null || detailJson.isEmpty) return const [];
    try {
      final detail = jsonDecode(detailJson);
      if (detail is Map) {
        final lines = <String>[];
        if (detail['reason'] != null) {
          lines.add('Lý do: ${detail['reason']}');
        }
        if (row['action'] == 'product_price_change') {
          final oldPrice = detail['oldPriceVnd'];
          final newPrice = detail['newPriceVnd'];
          if (oldPrice != null && newPrice != null) {
            lines.add('Giá: $oldPrice -> $newPrice VND');
          }
          if (detail['sku'] != null) {
            lines.add('SKU: ${detail['sku']}');
          }
        }
        if (row['action'] == 'user_role_change') {
          final fromRole = detail['fromRole'];
          final toRole = detail['toRole'];
          if (fromRole != null && toRole != null) {
            lines.add('Vai trò: $fromRole -> $toRole');
          }
        }
        if (row['action'] == 'user_create') {
          if (detail['role'] != null) {
            lines.add('Vai trò: ${detail['role']}');
          }
          if (detail['phone'] != null) {
            lines.add('SĐT: ${detail['phone']}');
          }
        }
        if (row['action'] == 'einvoice_issue' ||
            row['action'] == 'einvoice_cancel' ||
            row['action'] == 'einvoice_adjust') {
          if (detail['invoiceNumber'] != null) {
            lines.add('Số HĐ: ${detail['invoiceNumber']}');
          }
          if (detail['provider'] != null) {
            lines.add('NCC: ${detail['provider']}');
          }
        }
        return lines;
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  String _auditActionLabel(String action) {
    switch (action) {
      case 'period_lock':
        return 'Khóa sổ';
      case 'period_unlock':
        return 'Mở khóa';
      case 'journal_blocked_period_lock':
        return 'Chặn ghi sổ';
      case 'product_price_change':
        return 'Đổi giá SP';
      case 'user_create':
        return 'Tạo nhân viên';
      case 'user_role_change':
        return 'Đổi vai trò NV';
      case 'user_password_reset':
        return 'Đổi mật khẩu NV';
      case 'einvoice_issue':
        return 'Xuất HĐĐT';
      case 'einvoice_cancel':
        return 'Hủy HĐĐT';
      case 'einvoice_adjust':
        return 'Điều chỉnh HĐĐT';
      default:
        return action;
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildJournalTab() {
    return ListView(
      children: [
        _sectionHeader('Kỳ đã khóa'),
        if (_locks.isEmpty)
          const ListTile(title: Text('Chưa khóa kỳ nào'))
        else
          for (final lock in _locks)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(lock['periodYm']?.toString() ?? ''),
              subtitle: Text('Khóa lúc ${lock['lockedAt'] ?? ''}'),
              trailing: widget.isOwner
                  ? TextButton(
                      onPressed: () => _unlock(lock['periodYm'].toString()),
                      child: const Text('Mở khóa'),
                    )
                  : null,
            ),
        _sectionHeader('Nhật ký kiểm toán'),
        if (_audit.isEmpty)
          const ListTile(title: Text('Chưa có nhật ký'))
        else
          for (final row in _audit)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                '${_auditActionLabel(row['action']?.toString() ?? '')}'
                ' · ${row['entityId'] ?? ''}',
              ),
              subtitle: Text(
                [
                  row['at']?.toString() ?? '',
                  ..._auditDetailLines(row),
                ].where((v) => v.isNotEmpty).join('\n'),
              ),
            ),
        _sectionHeader('Nhật ký bút toán'),
        if (_entries.isEmpty)
          const ListTile(title: Text('Chưa có bút toán'))
        else
          for (final e in _entries)
            ListTile(
              title: Text('${e['sourceType']} · ${e['sourceId']}'),
              subtitle: Text('${e['periodYm']} · ${e['postedAt']}'),
            ),
      ],
    );
  }

  Widget _buildAccountLedgerTab() {
    final rows = _tbRows
        .where((r) => r['accountCode'] != null)
        .toList(growable: false);
    final lines = ((_accountLedger?['lines'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _accountCode,
                  decoration: const InputDecoration(labelText: 'Tài khoản'),
                  items: [
                    for (final row in rows)
                      DropdownMenuItem(
                        value: row['accountCode'].toString(),
                        child: Text(
                          '${row['accountCode']} ${row['name'] ?? ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _changeAccount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ValueKey(_periodYm),
                  initialValue: _periodYm,
                  decoration: const InputDecoration(labelText: 'Kỳ'),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: _changePeriod,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          title: Text(
            '${_accountLedger?['accountCode'] ?? _accountCode} '
            '${_accountLedger?['accountName'] ?? ''}',
          ),
          subtitle: Text(
            widget.storeId == null ? 'Tổng hợp' : 'Cửa hàng ${widget.storeId}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.first_page_outlined),
          title: const Text('Số dư đầu kỳ'),
          trailing: Text('${_accountLedger?['openingBalance'] ?? 0}'),
        ),
        if (lines.isEmpty)
          const ListTile(title: Text('Chưa có phát sinh trong kỳ'))
        else
          for (final line in lines)
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text('${line['sourceType']} · ${line['sourceId']}'),
              subtitle: Text(
                [
                  line['postedAt']?.toString() ?? '',
                  'Nợ ${line['debitVnd']} · Có ${line['creditVnd']}',
                ].where((v) => v.isNotEmpty).join('\n'),
              ),
              trailing: Text('${line['runningBalance']}'),
            ),
        ListTile(
          leading: const Icon(Icons.last_page_outlined),
          title: const Text('Số dư cuối kỳ'),
          trailing: Text('${_accountLedger?['closingBalance'] ?? 0}'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockHint = _periodLocked
        ? 'Kỳ $_periodYm đã khóa'
        : (_locks.isEmpty
              ? 'Chưa khóa kỳ nào'
              : 'Đã khóa: ${_locks.take(3).map((l) => l['periodYm']).join(', ')}');

    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Sổ cái'),
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
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(
                children: [
                  _buildJournalTab(),
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
                  _buildAccountLedgerTab(),
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
                        trailing: Text('${_pnl?['operatingExpenseVnd'] ?? 0}'),
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
