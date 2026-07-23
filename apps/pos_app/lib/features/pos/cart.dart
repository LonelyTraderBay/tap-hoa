import 'package:decimal/decimal.dart';

int _roundVndHalfUp(Decimal value) => value.round().toBigInt().toInt();

String _formatQty(Decimal qty) {
  if (qty == qty.truncate()) {
    return qty.truncate().toString();
  }
  return qty.toStringAsFixed(3);
}

class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.qty,
  });

  final String productId;
  final String name;
  final int unitPrice;
  final Decimal qty;

  int get lineTotal =>
      _roundVndHalfUp(Decimal.fromInt(unitPrice) * qty);

  CartLine copyWith({Decimal? qty}) => CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        qty: qty ?? this.qty,
      );
}

class SaleDraftLine {
  const SaleDraftLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final String qty;
  final int unitPrice;
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
  int discountVnd = 0;

  int get subtotalVnd => lines.fold(0, (sum, line) => sum + line.lineTotal);

  int get totalVnd => subtotalVnd - discountVnd;

  void add(CartLine line) => lines.add(line);

  void update(String productId, Decimal qty) {
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index == -1) {
      throw StateError('Cart line not found: $productId');
    }
    lines[index] = lines[index].copyWith(qty: qty);
  }

  void remove(String productId) {
    lines.removeWhere((line) => line.productId == productId);
  }

  SaleDraft toSaleDraft() => SaleDraft(
        lines: [
          for (final line in lines)
            SaleDraftLine(
              productId: line.productId,
              name: line.name,
              qty: _formatQty(line.qty),
              unitPrice: line.unitPrice,
              lineTotal: line.lineTotal,
            ),
        ],
        subtotalVnd: subtotalVnd,
        discountVnd: discountVnd,
        totalVnd: totalVnd,
      );
}
