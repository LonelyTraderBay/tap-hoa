import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final canEditThreshold = role == 'owner' || role == 'store_manager';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách nợ'),
        actions: [
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
          if (customers.isEmpty) {
            return const Center(child: Text('Không có khách nợ'));
          }
          return FutureBuilder<_AgingIndex>(
            future: _buildAgingIndex(database, storeId),
            builder: (context, agingSnap) {
              final aging = agingSnap.data;
              return ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final info = aging?.byCustomer[customer.id];
                  return ListTile(
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
                  );
                },
              );
            },
          );
        },
      ),
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
  final store = await (db.select(db.storesLocal)
        ..where((t) => t.id.equals(storeId)))
      .getSingleOrNull();
  final overdueDays = store?.debtOverdueDays ?? 30;
  final ledger = await (db.select(db.debtLedgerLocal)
        ..where((t) => t.storeId.equals(storeId)))
      .get();
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
