import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import 'customer_repository.dart';
import 'debt_payment_service.dart';
import 'record_debt_payment_sheet.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({
    super.key,
    required this.customerId,
    required this.repository,
    required this.debtPaymentService,
  });

  final String customerId;
  final CustomerRepository repository;
  final DebtPaymentService debtPaymentService;

  Future<void> _recordPayment(
    BuildContext context,
    CustomerRecord customer,
  ) async {
    final ok = await RecordDebtPaymentSheet.show(
      context,
      customerId: customer.id,
      balanceVnd: customer.balanceVnd,
      debtPaymentService: debtPaymentService,
    );
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thu nợ (chờ sync)')),
    );
  }

  Future<void> _editCreditLimit(
    BuildContext context,
    CustomerRecord customer,
  ) async {
    final controller = TextEditingController(
      text: customer.creditLimitVnd?.toString() ?? '',
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sửa hạn mức'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Hạn mức (VND)',
            helperText: 'Để trống = không hạn mức',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final limitText = controller.text.trim();
    controller.dispose();
    if (submitted != true || !context.mounted) return;

    final limit = limitText.isEmpty ? null : int.tryParse(limitText);
    if (limitText.isNotEmpty && limit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn mức không hợp lệ')),
      );
      return;
    }

    await repository.updateCreditLimit(
      customerId: customer.id,
      creditLimitVnd: limit,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật hạn mức (chờ sync)')),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sale_debt':
        return 'Bán nợ';
      case 'payment':
        return 'Thu nợ';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CustomerRecord?>(
      stream: repository.watchById(customerId),
      builder: (context, customerSnapshot) {
        final customer = customerSnapshot.data;
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Khách hàng')),
            body: const Center(child: Text('Không tìm thấy khách')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(customer.name)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer.phone != null) Text('SĐT: ${customer.phone}'),
                    const SizedBox(height: 4),
                    Text(
                      'Còn nợ: ${customer.balanceVnd} VND',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.creditLimitVnd == null
                          ? 'Hạn mức: Không hạn mức'
                          : 'Hạn mức: ${customer.creditLimitVnd} VND',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: customer.balanceVnd <= 0
                              ? null
                              : () => _recordPayment(context, customer),
                          child: const Text('Thu nợ'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _editCreditLimit(context, customer),
                          child: const Text('Sửa hạn mức'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Lịch sử',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<DebtLedgerLocalData>>(
                  stream: repository.watchLedger(customerId),
                  builder: (context, ledgerSnapshot) {
                    final entries = ledgerSnapshot.data ?? [];
                    if (entries.isEmpty) {
                      return const Center(child: Text('Chưa có giao dịch'));
                    }
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final time = entry.clientCreatedAt.toLocal();
                        final timeLabel =
                            '${time.day.toString().padLeft(2, '0')}/'
                            '${time.month.toString().padLeft(2, '0')}/'
                            '${time.year} '
                            '${time.hour.toString().padLeft(2, '0')}:'
                            '${time.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          title: Text(_typeLabel(entry.type)),
                          subtitle: Text(
                            '$timeLabel · sau: ${entry.balanceAfterVnd} VND',
                          ),
                          trailing: Text('${entry.amountVnd} VND'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
