import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/pdf_fonts.dart';
import '../reports/ict_date.dart';
import 'receipt_windows_raw.dart';

const _receiptWidthMm = 58.0;
const _maxNameChars = 24;

enum _ReceiptPostCheckoutAction { print, share }

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

String receiptPdfFileName(String saleId) {
  final safeId = shortenSaleId(
    saleId,
  ).replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  return 'receipt-${safeId.isEmpty ? 'sale' : safeId}.pdf';
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
      theme: pw.ThemeData.withFont(base: pdfFontRegular, bold: pdfFontBold),
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
            pw.Text(
              'Tiền mặt: ${formatReceiptVnd(cashVnd)} VND',
              style: textStyle,
            ),
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
            pw.Text(
              'Công nợ: ${formatReceiptVnd(debtVnd)} VND',
              style: textStyle,
            ),
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

class ReceiptPdfShareResult {
  const ReceiptPdfShareResult({
    required this.path,
    required this.openedFallback,
  });

  final String path;
  final bool openedFallback;
}

Future<String> writeReceiptPdfToTemp({
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
  final bytes = await buildReceiptPdf(
    storeName: storeName,
    saleId: saleId,
    soldAt: soldAt,
    lines: lines,
    totalVnd: totalVnd,
    cashVnd: cashVnd,
    transferVnd: transferVnd,
    debtVnd: debtVnd,
    customerName: customerName,
  );
  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}${Platform.pathSeparator}${receiptPdfFileName(saleId)}';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

Future<ReceiptPdfShareResult> shareReceiptPdf({
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
  final path = await writeReceiptPdfToTemp(
    storeName: storeName,
    saleId: saleId,
    soldAt: soldAt,
    lines: lines,
    totalVnd: totalVnd,
    cashVnd: cashVnd,
    transferVnd: transferVnd,
    debtVnd: debtVnd,
    customerName: customerName,
  );
  final fileName = receiptPdfFileName(saleId);

  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        fileNameOverrides: [fileName],
        subject: 'Hóa đơn ${shortenSaleId(saleId)}',
      ),
    );
    if (Platform.isWindows && result.status == ShareResultStatus.unavailable) {
      await _revealReceiptPdf(path);
      return ReceiptPdfShareResult(path: path, openedFallback: true);
    }
  } catch (_) {
    if (!Platform.isWindows) rethrow;
    await _revealReceiptPdf(path);
    return ReceiptPdfShareResult(path: path, openedFallback: true);
  }

  return ReceiptPdfShareResult(path: path, openedFallback: false);
}

Future<void> _revealReceiptPdf(String path) async {
  await Clipboard.setData(ClipboardData(text: path));
  await Process.start('explorer.exe', ['/select,', path]);
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
  String printMode = 'ask',
  String? printerName,
}) async {
  final action = await showDialog<_ReceiptPostCheckoutAction>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Hóa đơn'),
        content: const Text('Bạn muốn in hoặc gửi hóa đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Bỏ qua'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_ReceiptPostCheckoutAction.share),
            child: const Text('Gửi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_ReceiptPostCheckoutAction.print),
            child: const Text('In'),
          ),
        ],
      );
    },
  );
  if (!context.mounted || action == null) return;

  if (action == _ReceiptPostCheckoutAction.share) {
    try {
      final result = await shareReceiptPdf(
        storeName: storeName,
        saleId: saleId,
        soldAt: soldAt,
        lines: lines,
        totalVnd: totalVnd,
        cashVnd: cashVnd,
        transferVnd: transferVnd,
        debtVnd: debtVnd,
        customerName: customerName,
      );
      if (!context.mounted) return;
      final message = result.openedFallback
          ? 'Đã lưu PDF hóa đơn: ${result.path}'
          : 'Đã mở chia sẻ hóa đơn';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gửi hóa đơn thất bại')));
      }
    }
    return;
  }

  final effectivePrintMode = printMode == 'ask' ? 'pdf' : printMode;

  if (effectivePrintMode == 'escpos') {
    try {
      final bytes = buildReceiptEscPosBytes(
        storeName: storeName,
        saleId: saleId,
        soldAt: soldAt,
        lines: lines,
        totalVnd: totalVnd,
        cashVnd: cashVnd,
        transferVnd: transferVnd,
        debtVnd: debtVnd,
        customerName: customerName,
      );
      final name = printerName?.trim() ?? '';
      if (name.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa chọn máy in ESC/POS — chuyển PDF'),
            ),
          );
        }
      } else {
        final sent = await sendRawToWindowsPrinter(name, bytes);
        if (sent) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã gửi in ESC/POS')));
          }
          return;
        }
        if (context.mounted) {
          final usePdf = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('In ESC/POS thất bại'),
              content: const Text('Gửi máy in thô thất bại. In PDF?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Không'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('PDF'),
                ),
              ],
            ),
          );
          if (usePdf != true || !context.mounted) return;
        }
      }
    } catch (_) {
      // fall through to PDF
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('In hóa đơn thất bại')));
    }
  }
}

/// Minimal ESC/POS byte builder (58mm text receipt).
Uint8List buildReceiptEscPosBytes({
  required String storeName,
  required String saleId,
  required DateTime soldAt,
  required List<ReceiptLine> lines,
  required int totalVnd,
  required int cashVnd,
  required int transferVnd,
  required int debtVnd,
  String? customerName,
}) {
  final buffer = BytesBuilder();
  void writeln(String text) {
    buffer.add(utf8.encode('$text\n'));
  }

  buffer.add([0x1B, 0x40]); // init
  writeln(storeName);
  writeln(formatIctDateTime(soldAt));
  writeln('DH: ${shortenSaleId(saleId)}');
  writeln('-' * 32);
  for (final line in lines) {
    writeln(truncateReceiptName(line.name));
    writeln(
      '  ${line.qtyLabel} x ${formatReceiptVnd(line.unitPriceVnd)} = ${formatReceiptVnd(line.lineTotalVnd)}',
    );
  }
  writeln('-' * 32);
  writeln('TONG: ${formatReceiptVnd(totalVnd)} VND');
  if (cashVnd > 0) writeln('TM: ${formatReceiptVnd(cashVnd)}');
  if (transferVnd > 0) writeln('CK: ${formatReceiptVnd(transferVnd)}');
  if (debtVnd > 0) writeln('NO: ${formatReceiptVnd(debtVnd)}');
  if (customerName != null && customerName.isNotEmpty) {
    writeln('KH: $customerName');
  }
  buffer.add([0x1D, 0x56, 0x00]); // cut
  return buffer.toBytes();
}
