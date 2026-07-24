import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/pdf_fonts.dart';
import '../reports/ict_date.dart';

const _receiptWidthMm = 58.0;
const _maxNameChars = 24;

class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.qtyLabel,
    required this.unitPriceVnd,
    required this.lineTotalVnd,
  });

  final String name;
  final String qtyLabel;
  final int unitPriceVnd;
  final int lineTotalVnd;
}

String formatReceiptVnd(int vnd) {
  final digits = vnd.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String truncateReceiptName(String name, {int maxChars = _maxNameChars}) {
  final trimmed = name.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars - 1)}…';
}

String shortenSaleId(String saleId) {
  final trimmed = saleId.trim();
  if (trimmed.length <= 12) return trimmed;
  return trimmed.substring(0, 12);
}

String formatIctDateTime(DateTime soldAt) {
  final ict = soldAt.toUtc().add(ictOffset);
  final day = ict.day.toString().padLeft(2, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final year = ict.year.toString();
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

Future<Uint8List> buildReceiptPdf({
  required String storeName,
  required String saleId,
  required DateTime soldAt,
  required List<ReceiptLine> lines,
  required int totalVnd,
  required int cashVnd,
  required int transferVnd,
  required int debtVnd,
  String? customerName,
}) async {
  await ensurePdfFontsLoaded();

  final doc = pw.Document();
  final pageFormat = PdfPageFormat(
    _receiptWidthMm * PdfPageFormat.mm,
    double.infinity,
    marginAll: 4 * PdfPageFormat.mm,
  );
  final textStyle = pw.TextStyle(fontSize: 8, font: pdfFontRegular);
  final boldStyle = pw.TextStyle(fontSize: 8, font: pdfFontBold);

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: pdfFontRegular,
        bold: pdfFontBold,
      ),
      build: (context) {
        final children = <pw.Widget>[
          pw.Text(
            storeName.trim(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, font: pdfFontBold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(formatIctDateTime(soldAt), style: textStyle),
          pw.Text('Mã đơn: ${shortenSaleId(saleId)}', style: textStyle),
          if (customerName != null && customerName.trim().isNotEmpty)
            pw.Text('Khách: ${customerName.trim()}', style: textStyle),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),
        ];

        for (final line in lines) {
          children.addAll([
            pw.Text(truncateReceiptName(line.name), style: boldStyle),
            pw.Text(
              '${line.qtyLabel} x ${formatReceiptVnd(line.unitPriceVnd)} = ${formatReceiptVnd(line.lineTotalVnd)}',
              style: textStyle,
            ),
            pw.SizedBox(height: 4),
          ]);
        }

        children.addAll([
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Text(
            'Tổng cộng: ${formatReceiptVnd(totalVnd)} VND',
            style: boldStyle,
          ),
        ]);

        if (cashVnd > 0) {
          children.add(
            pw.Text('Tiền mặt: ${formatReceiptVnd(cashVnd)} VND', style: textStyle),
          );
        }
        if (transferVnd > 0) {
          children.add(
            pw.Text(
              'Chuyển khoản: ${formatReceiptVnd(transferVnd)} VND',
              style: textStyle,
            ),
          );
        }
        if (debtVnd > 0) {
          children.add(
            pw.Text('Công nợ: ${formatReceiptVnd(debtVnd)} VND', style: textStyle),
          );
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: children,
        );
      },
    ),
  );

  return doc.save();
}

Future<void> promptAndPrintReceipt(
  BuildContext context, {
  required String storeName,
  required String saleId,
  required DateTime soldAt,
  required List<ReceiptLine> lines,
  required int totalVnd,
  required int cashVnd,
  required int transferVnd,
  required int debtVnd,
  String? customerName,
}) async {
  final shouldPrint = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('In hóa đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Có'),
          ),
        ],
      );
    },
  );
  if (!context.mounted || shouldPrint != true) return;

  try {
    await Printing.layoutPdf(
      name: 'receipt-$saleId',
      onLayout: (_) => buildReceiptPdf(
        storeName: storeName,
        saleId: saleId,
        soldAt: soldAt,
        lines: lines,
        totalVnd: totalVnd,
        cashVnd: cashVnd,
        transferVnd: transferVnd,
        debtVnd: debtVnd,
        customerName: customerName,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In hóa đơn thất bại')),
      );
    }
  }
}
