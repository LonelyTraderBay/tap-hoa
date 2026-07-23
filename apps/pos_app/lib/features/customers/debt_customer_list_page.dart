import 'package:flutter/material.dart';

import 'customer_detail_page.dart';
import 'customer_repository.dart';
import 'debt_payment_service.dart';

class DebtCustomerListPage extends StatelessWidget {
  const DebtCustomerListPage({
    super.key,
    required this.repository,
    required this.debtPaymentService,
  });

  final CustomerRepository repository;
  final DebtPaymentService debtPaymentService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khách nợ')),
      body: StreamBuilder<List<CustomerRecord>>(
        stream: repository.watchWithDebt(),
        builder: (context, snapshot) {
          final customers = snapshot.data ?? [];
          if (customers.isEmpty) {
            return const Center(child: Text('Không có khách nợ'));
          }
          return ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer.name),
                subtitle: customer.phone != null ? Text(customer.phone!) : null,
                trailing: Text('${customer.balanceVnd} VND'),
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
      ),
    );
  }
}
