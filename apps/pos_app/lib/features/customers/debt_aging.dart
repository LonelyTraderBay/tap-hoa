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

  for (final e in sorted) {
    if (e.type == 'sale_debt' && e.amountVnd > 0) {
      open.add((remaining: e.amountVnd, at: e.clientCreatedAt));
      continue;
    }
    if ((e.type == 'payment' || e.type == 'sale_return_credit') &&
        e.amountVnd > 0) {
      var left = e.amountVnd;
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
