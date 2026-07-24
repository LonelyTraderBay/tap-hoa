import 'package:decimal/decimal.dart';

/// Convert sell qty to base stock qty. Null/empty packSize means 1:1.
Decimal toBaseQty(Decimal sellQty, Decimal? packSize) {
  if (packSize == null) return sellQty;
  return sellQty * packSize;
}

Decimal? parsePackSize(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final v = Decimal.parse(raw.trim());
    if (v <= Decimal.zero) return null;
    return v;
  } catch (_) {
    return null;
  }
}
