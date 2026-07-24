import 'dart:typed_data';

/// Minimal ESC/POS byte builder for 58mm thermal printers (UTF-8 text).
/// Windows raw send can use these bytes; PDF remains the fallback path.
List<int> buildReceiptEscPosBytes({
  required String storeName,
  required String saleId,
  required String soldAtLabel,
  required List<({String name, String qtyLabel, int unitPrice, int lineTotal})>
      lines,
  required int totalVnd,
  required int cashVnd,
  required int transferVnd,
  required int debtVnd,
  String? customerName,
}) {
  final out = <int>[];
  void raw(List<int> bytes) => out.addAll(bytes);
  void text(String s) {
    raw(s.codeUnits);
    raw([0x0A]);
  }

  // ESC @ init
  raw([0x1B, 0x40]);
  // Align center
  raw([0x1B, 0x61, 1]);
  text(storeName);
  raw([0x1B, 0x61, 0]);
  text(soldAtLabel);
  text('Ma don: ${saleId.length > 12 ? saleId.substring(0, 12) : saleId}');
  if (customerName != null && customerName.trim().isNotEmpty) {
    text('Khach: ${customerName.trim()}');
  }
  text('--------------------------------');
  for (final line in lines) {
    text(line.name);
    text(
      '${line.qtyLabel} x ${line.unitPrice} = ${line.lineTotal}',
    );
  }
  text('--------------------------------');
  text('Tong: $totalVnd VND');
  if (cashVnd > 0) text('Tien mat: $cashVnd');
  if (transferVnd > 0) text('CK: $transferVnd');
  if (debtVnd > 0) text('No: $debtVnd');
  text('');
  text('Cam on!');
  // Feed + cut
  raw([0x0A, 0x0A, 0x0A]);
  raw([0x1D, 0x56, 0x00]);
  return out;
}

Uint8List buildReceiptEscPosUint8List({
  required String storeName,
  required String saleId,
  required String soldAtLabel,
  required List<({String name, String qtyLabel, int unitPrice, int lineTotal})>
      lines,
  required int totalVnd,
  required int cashVnd,
  required int transferVnd,
  required int debtVnd,
  String? customerName,
}) {
  return Uint8List.fromList(
    buildReceiptEscPosBytes(
      storeName: storeName,
      saleId: saleId,
      soldAtLabel: soldAtLabel,
      lines: lines,
      totalVnd: totalVnd,
      cashVnd: cashVnd,
      transferVnd: transferVnd,
      debtVnd: debtVnd,
      customerName: customerName,
    ),
  );
}
