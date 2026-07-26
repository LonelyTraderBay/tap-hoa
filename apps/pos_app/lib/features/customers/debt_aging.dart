// FIFO debt aging — mirror of API debt-aging.ts

class DebtLedgerRow {
  const DebtLedgerRow({
    required this.type,
    required this.amountVnd,
    required this.clientCreatedAt,
  });

  final String type;
  final int amountVnd;
  final DateTime clientCreatedAt;
}

class DebtAgingResult {
  const DebtAgingResult({
    required this.oldestUnpaidAt,
    required this.daysOutstanding,
    required this.overdue,
  });

  final DateTime? oldestUnpaidAt;
  final int daysOutstanding;
  final bool overdue;
}

class RemoteDebtAgingCustomer {
  const RemoteDebtAgingCustomer({
    required this.customerId,
    required this.storeId,
    required this.name,
    this.phone,
    required this.balanceVnd,
    required this.debtOverdueDays,
    this.oldestUnpaidAt,
    required this.daysOutstanding,
    required this.overdue,
  });

  factory RemoteDebtAgingCustomer.fromJson(Map<String, dynamic> json) {
    final oldest = json['oldestUnpaidAt'] as String?;
    return RemoteDebtAgingCustomer(
      customerId: json['customerId'] as String,
      storeId: json['storeId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      balanceVnd: json['balanceVnd'] as int,
      debtOverdueDays: json['debtOverdueDays'] as int,
      oldestUnpaidAt: oldest == null ? null : DateTime.parse(oldest),
      daysOutstanding: json['daysOutstanding'] as int,
      overdue: json['overdue'] as bool,
    );
  }

  final String customerId;
  final String storeId;
  final String name;
  final String? phone;
  final int balanceVnd;
  final int debtOverdueDays;
  final DateTime? oldestUnpaidAt;
  final int daysOutstanding;
  final bool overdue;
}

class DebtAgingReport {
  const DebtAgingReport({
    required this.scope,
    this.storeId,
    required this.storeIds,
    this.debtOverdueDays,
    required this.customers,
  });

  factory DebtAgingReport.fromJson(Map<String, dynamic> json) {
    return DebtAgingReport(
      scope: json['scope'] as String,
      storeId: json['storeId'] as String?,
      storeIds: (json['storeIds'] as List<dynamic>).cast<String>(),
      debtOverdueDays: json['debtOverdueDays'] as int?,
      customers: (json['customers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(RemoteDebtAgingCustomer.fromJson)
          .toList(),
    );
  }

  final String scope;
  final String? storeId;
  final List<String> storeIds;
  final int? debtOverdueDays;
  final List<RemoteDebtAgingCustomer> customers;

  int get totalBalanceVnd {
    return customers.fold(0, (sum, customer) => sum + customer.balanceVnd);
  }

  int get overdueCount {
    return customers.where((customer) => customer.overdue).length;
  }
}

const ictOffset = Duration(hours: 7);

int ictDayDiff(DateTime from, DateTime to) {
  final fromIct = from.toUtc().add(ictOffset);
  final toIct = to.toUtc().add(ictOffset);
  final a = DateTime.utc(fromIct.year, fromIct.month, fromIct.day);
  final b = DateTime.utc(toIct.year, toIct.month, toIct.day);
  return b.difference(a).inDays;
}

DebtAgingResult computeDebtAging(
  List<DebtLedgerRow> entries,
  int debtOverdueDays, {
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now().toUtc();
  final sorted = [...entries]
    ..sort((a, b) => a.clientCreatedAt.compareTo(b.clientCreatedAt));

  final open = <({int remaining, DateTime at})>[];
  void reduceOpenDebt(int amountVnd) {
    var left = amountVnd;
    while (left > 0 && open.isNotEmpty) {
      final head = open.first;
      final take = head.remaining < left ? head.remaining : left;
      final nextRemaining = head.remaining - take;
      left -= take;
      open.removeAt(0);
      if (nextRemaining > 0) {
        open.insert(0, (remaining: nextRemaining, at: head.at));
      }
    }
  }

  for (final e in sorted) {
    if ((e.type == 'sale_debt' ||
            (e.type == 'debt_adjust' && e.amountVnd > 0)) &&
        e.amountVnd > 0) {
      open.add((remaining: e.amountVnd, at: e.clientCreatedAt));
      continue;
    }
    if ((e.type == 'payment' || e.type == 'sale_return_credit') &&
        e.amountVnd > 0) {
      reduceOpenDebt(e.amountVnd);
    }
    if (e.type == 'debt_adjust' && e.amountVnd < 0) {
      reduceOpenDebt(e.amountVnd.abs());
    }
  }

  if (open.isEmpty) {
    return const DebtAgingResult(
      oldestUnpaidAt: null,
      daysOutstanding: 0,
      overdue: false,
    );
  }

  final oldest = open.first.at;
  final days = ictDayDiff(oldest, now).clamp(0, 365000);
  return DebtAgingResult(
    oldestUnpaidAt: oldest,
    daysOutstanding: days,
    overdue: days > debtOverdueDays,
  );
}
