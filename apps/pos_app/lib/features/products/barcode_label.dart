import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _labelWidthMm = 50.0;
const _labelHeightMm = 30.0;

String formatPriceLabelVnd(int vnd) {
  final digits = vnd.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return '$buffer VND';
}

Barcode? barcodeTypeForCode(String code) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;

  if (RegExp(r'^\d{13}$').hasMatch(trimmed)) {
    try {
      return Barcode.ean13()..verify(trimmed);
    } catch (_) {
      return Barcode.code128();
    }
  }

  if (RegExp(r'^\d{8}$').hasMatch(trimmed)) {
    try {
      return Barcode.ean8()..verify(trimmed);
    } catch (_) {
      return Barcode.code128();
    }
  }

  return Barcode.code128();
}

String truncateLabelTitle(String title, {int maxChars = 28}) {
  final trimmed = title.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars - 1)}…';
}

Future<Uint8List> buildProductLabelPdf({
  required String title,
  required String priceLabel,
  required String code,
  required int copies,
}) async {
  final doc = pw.Document();
  final trimmedCode = code.trim();
  final barcode = barcodeTypeForCode(trimmedCode);
  final pageFormat = PdfPageFormat(
    _labelWidthMm * PdfPageFormat.mm,
    _labelHeightMm * PdfPageFormat.mm,
    marginAll: 2 * PdfPageFormat.mm,
  );

  final safeCopies = copies.clamp(1, 20);

  for (var i = 0; i < safeCopies; i++) {
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                truncateLabelTitle(title),
                style: const pw.TextStyle(fontSize: 8),
                maxLines: 2,
              ),
              if (barcode != null && trimmedCode.isNotEmpty)
                pw.Expanded(
                  child: pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: barcode,
                      data: trimmedCode,
                      drawText: true,
                      height: 28,
                      textStyle: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                )
              else
                pw.Text(
                  trimmedCode,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Text(
                priceLabel,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return doc.save();
}

Future<void> printProductLabels({
  required String title,
  required String priceLabel,
  required String code,
  required int copies,
}) {
  return Printing.layoutPdf(
    name: 'product-labels',
    onLayout: (_) => buildProductLabelPdf(
      title: title,
      priceLabel: priceLabel,
      code: code,
      copies: copies,
    ),
  );
}

Future<int?> showLabelCopiesDialog(BuildContext context) {
  var copies = 1;

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('In tem'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Số bản: $copies'),
                Slider(
                  value: copies.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '$copies',
                  onChanged: (value) =>
                      setState(() => copies = value.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(copies),
                child: const Text('In'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> promptAndPrintProductLabel(
  BuildContext context, {
  required String title,
  required int basePriceVnd,
  required String barcode,
  required String sku,
}) async {
  final copies = await showLabelCopiesDialog(context);
  if (!context.mounted || copies == null) return;

  final code = barcode.trim().isNotEmpty ? barcode.trim() : sku.trim();
  if (code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần mã vạch hoặc SKU để in tem')),
    );
    return;
  }

  await printProductLabels(
    title: title,
    priceLabel: formatPriceLabelVnd(basePriceVnd),
    code: code,
    copies: copies,
  );
}
