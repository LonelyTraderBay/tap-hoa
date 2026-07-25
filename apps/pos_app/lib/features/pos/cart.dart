import 'package:decimal/decimal.dart';

int _roundVndHalfUp(Decimal value) => value.round().toBigInt().toInt();

int _lineGrossVnd({required int unitPrice, required Decimal qty}) =>
    _roundVndHalfUp(Decimal.fromInt(unitPrice) * qty);

int _clampVnd(int value, int max) {
  if (value < 0) return 0;
  if (value > max) return max;
  return value;
}

String _formatQty(Decimal qty) {
  if (qty == qty.truncate()) {
    return qty.truncate().toString();
  }
  return qty.toStringAsFixed(3);
}

class CartLine {
  CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    this.isWeighted = false,
    int discountVnd = 0,
  }) : discountVnd = _clampVnd(
         discountVnd,
         _lineGrossVnd(unitPrice: unitPrice, qty: qty),
       );

  final String productId;
  final String name;
  final int unitPrice;
  final Decimal qty;
  final bool isWeighted;
  final int discountVnd;

  int get grossTotalVnd => _lineGrossVnd(unitPrice: unitPrice, qty: qty);

  int get lineTotal => grossTotalVnd - discountVnd;

  CartLine copyWith({Decimal? qty, bool? isWeighted, int? discountVnd}) =>
      CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        qty: qty ?? this.qty,
        isWeighted: isWeighted ?? this.isWeighted,
        discountVnd: discountVnd ?? this.discountVnd,
      );
}

class SaleDraftLine {
  const SaleDraftLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.discountVnd,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final String qty;
  final int unitPrice;
  final int discountVnd;
  final int lineTotal;
}

class SaleDraft {
  const SaleDraft({
    required this.lines,
    required this.subtotalVnd,
    required this.discountVnd,
    required this.totalVnd,
  });

  final List<SaleDraftLine> lines;
  final int subtotalVnd;
  final int discountVnd;
  final int totalVnd;
}

class Cart {
  final lines = <CartLine>[];
  int _discountVnd = 0;

  int get discountVnd => _discountVnd;

  set discountVnd(int value) {
    _discountVnd = _clampVnd(value, subtotalVnd);
  }

  int get subtotalVnd => lines.fold(0, (sum, line) => sum + line.lineTotal);

  int get totalVnd => subtotalVnd - discountVnd;

  void add(CartLine line) => lines.add(line);

  void _clampInvoiceDiscount() {
    _discountVnd = _clampVnd(_discountVnd, subtotalVnd);
  }

  void update(String productId, Decimal qty) {
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index == -1) {
      throw StateError('Cart line not found: $productId');
    }
    lines[index] = lines[index].copyWith(qty: qty);
    _clampInvoiceDiscount();
  }

  void updateLineDiscount(String productId, int discountVnd) {
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index == -1) {
      throw StateError('Cart line not found: $productId');
    }
    lines[index] = lines[index].copyWith(discountVnd: discountVnd);
    _clampInvoiceDiscount();
  }

  void remove(String productId) {
    lines.removeWhere((line) => line.productId == productId);
    _clampInvoiceDiscount();
  }

  SaleDraft toSaleDraft() => SaleDraft(
    lines: [
      for (final line in lines)
        SaleDraftLine(
          productId: line.productId,
          name: line.name,
          qty: _formatQty(line.qty),
          unitPrice: line.unitPrice,
          discountVnd: line.discountVnd,
          lineTotal: line.lineTotal,
        ),
    ],
    subtotalVnd: subtotalVnd,
    discountVnd: discountVnd,
    totalVnd: totalVnd,
  );
}
