import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/database.dart';
import 'customer_detail_page.dart';
import 'customer_repository.dart';
import 'debt_aging.dart';
import 'debt_payment_service.dart';
import 'debt_settings_sheet.dart';

class DebtCustomerListPage extends StatelessWidget {
  const DebtCustomerListPage({
    super.key,
    required this.repository,
    required this.debtPaymentService,
    this.database,
    this.storeId,
    this.dio,
    this.role,
  });

  final CustomerRepository repository;
  final DebtPaymentService debtPaymentService;
  final AppDatabase? database;
  final String? storeId;
  final Dio? dio;
  final String? role;

  bool get _canLoadAggregate {
    return dio != null && (role == 'owner' || role == 'store_manager');
  }

  Future<void> _exportArCsv(BuildContext context) async {
    final client = dio;
    if (client == null) return;
    try {
      final response = await client.get<Map<String, dynamic>>(
        '/reports/ar.csv',
      );
      final csv = response.data?['csv'] as String?;
      if (csv == null) {
        throw StateError('Empty AR CSV response');
      }
      final dir = await getTemporaryDirectory();
      const fileName = 'accounts-receivable-all.csv';
      final path = '${dir.path}${Platform.pathSeparator}$fileName';
      await File(path).writeAsString(csv, flush: true);
      var openedFallback = false;
      try {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path, mimeType: 'text/csv')],
            fileNameOverrides: const [fileName],
            subject: 'Công nợ phải thu',
          ),
        );
        if (Platform.isWindows &&
            result.status == ShareResultStatus.unavailable) {
          await _revealCsv(path);
          openedFallback = true;
        }
      } catch (_) {
        if (!Platform.isWindows) rethrow;
        await _revealCsv(path);
        openedFallback = true;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            openedFallback ? 'Đã mở CSV: $path' : 'Đã tạo CSV công nợ',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất CSV công nợ thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEditThreshold = role == 'owner' || role == 'store_manager';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách nợ'),
        actions: [
          if (_canLoadAggregate)
            IconButton(
              tooltip: 'Xuất CSV công nợ',
              icon: const Icon(Icons.file_download_outlined),
              onPressed: () => _exportArCsv(context),
            ),
          if (canEditThreshold &&
              database != null &&
              storeId != null &&
              dio != null)
            IconButton(
              tooltip: 'Ngưỡng quá hạn',
              icon: const Icon(Icons.tune),
              onPressed: () => showDebtSettingsSheet(
                context,
                db: database!,
                dio: dio!,
                storeId: storeId!,
                role: role!,
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<CustomerRecord>>(
        stream: repository.watchWithDebt(),
        builder: (context, snapshot) {
          final customers = snapshot.data ?? [];
          if (customers.isEmpty && !_canLoadAggregate) {
            return const Center(child: Text('Không có khách nợ'));
          }
          return FutureBuilder<_AgingIndex>(
            future: _buildAgingIndex(database, storeId),
            builder: (context, agingSnap) {
              final aging = agingSnap.data;
              return ListView(
                children: [
                  if (_canLoadAggregate) _AggregateDebtAgingSection(dio: dio!),
                  if (_canLoadAggregate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Danh sách cục bộ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (customers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có khách nợ cục bộ'),
                    )
                  else
                    ...customers.map((customer) {
                      final info = aging?.byCustomer[customer.id];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(customer.name),
                            subtitle: customer.phone != null
                                ? Text(customer.phone!)
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${customer.balanceVnd} VND'),
                                if (info != null && info.daysOutstanding > 0)
                                  Text(
                                    '${info.daysOutstanding} ngày'
                                    '${info.overdue ? ' · Quá hạn' : ''}',
                                    style: TextStyle(
                                      color: info.overdue ? Colors.red : null,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CustomerDetailPage(
                                    customerId: customer.id,
                                    repository: repository,
                                    debtPaymentService: debtPaymentService,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _revealCsv(String path) async {
  await Clipboard.setData(ClipboardData(text: path));
  await Process.start('explorer.exe', ['/select,', path]);
}

Future<DebtAgingReport> _fetchAggregateDebtAging(Dio dio) async {
  final response = await dio.get<Map<String, dynamic>>('/reports/debt-aging');
  final data = response.data;
  if (data == null) {
    throw StateError('Empty debt aging response');
  }
  return DebtAgingReport.fromJson(data);
}

class _AggregateDebtAgingSection extends StatelessWidget {
  const _AggregateDebtAgingSection({required this.dio});

  final Dio dio;

  String _shortId(String value) {
    return value.length <= 8 ? value : value.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DebtAgingReport>(
      future: _fetchAggregateDebtAging(dio),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ListTile(
              title: Text('Tổng công nợ'),
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Card(
            margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ListTile(
              title: Text('Tổng công nợ'),
              subtitle: Text('Không tải được dữ liệu tổng'),
            ),
          );
        }
        final report = snapshot.data!;
        final customers = report.customers;
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ExpansionTile(
            title: const Text('Tổng công nợ'),
            subtitle: Text(
              '${report.totalBalanceVnd} VND · '
              '${customers.length} khách · '
              '${report.overdueCount} quá hạn · '
              '${report.storeIds.length} cửa hàng',
            ),
            children: [
              if (customers.isEmpty)
                const ListTile(title: Text('Không có công nợ tổng'))
              else
                ...customers.map(
                  (customer) => ListTile(
                    title: Text(customer.name),
                    subtitle: Text(
                      'CH ${_shortId(customer.storeId)}'
                      '${customer.phone == null ? '' : ' · ${customer.phone}'}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${customer.balanceVnd} VND'),
                        Text(
                          '${customer.daysOutstanding} ngày'
                          '${customer.overdue ? ' · Quá hạn' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customer.overdue ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AgingIndex {
  _AgingIndex(this.byCustomer);
  final Map<String, DebtAgingResult> byCustomer;
}

Future<_AgingIndex> _buildAgingIndex(AppDatabase? db, String? storeId) async {
  if (db == null || storeId == null) {
    return _AgingIndex({});
  }
  final store = await (db.select(
    db.storesLocal,
  )..where((t) => t.id.equals(storeId))).getSingleOrNull();
  final overdueDays = store?.debtOverdueDays ?? 30;
  final ledger = await (db.select(
    db.debtLedgerLocal,
  )..where((t) => t.storeId.equals(storeId))).get();
  final byCustomer = <String, List<DebtLedgerRow>>{};
  for (final e in ledger) {
    byCustomer
        .putIfAbsent(e.customerId, () => [])
        .add(
          DebtLedgerRow(
            type: e.type,
            amountVnd: e.amountVnd,
            clientCreatedAt: e.clientCreatedAt,
          ),
        );
  }
  return _AgingIndex({
    for (final entry in byCustomer.entries)
      entry.key: computeDebtAging(entry.value, overdueDays),
  });
}
