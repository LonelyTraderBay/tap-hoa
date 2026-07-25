import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../data/local/database.dart';

/// Receipt print preferences stored in MetaLocal.
class ReceiptPrintSettingsPage extends StatefulWidget {
  const ReceiptPrintSettingsPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ReceiptPrintSettingsPage> createState() =>
      _ReceiptPrintSettingsPageState();
}

class _ReceiptPrintSettingsPageState extends State<ReceiptPrintSettingsPage> {
  String _mode = 'ask';
  String? _printerName;
  List<Printer> _printers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await widget.db.metaValue('receiptPrintMode') ?? 'ask';
    final printer = await widget.db.metaValue('receiptPrinterName');
    List<Printer> printers = [];
    try {
      printers = await Printing.listPrinters();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _printerName = printer;
      _printers = printers;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.db.setMetaValue('receiptPrintMode', _mode);
    await widget.db.setMetaValue(
      'receiptPrinterName',
      _printerName ?? '',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cấu hình in')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('In hóa đơn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Chế độ in'),
                RadioGroup<String>(
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v ?? 'ask'),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Hỏi mỗi lần (ask)'),
                        value: 'ask',
                      ),
                      RadioListTile<String>(
                        title: Text('PDF (hộp thoại hệ thống)'),
                        value: 'pdf',
                      ),
                      RadioListTile<String>(
                        title: Text('ESC/POS thô (Windows)'),
                        value: 'escpos',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _printers.any((p) => p.name == _printerName)
                      ? _printerName
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Máy in nhiệt (ESC/POS)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('(Chưa chọn)'),
                    ),
                    for (final p in _printers)
                      DropdownMenuItem<String?>(
                        value: p.name,
                        child: Text(p.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _printerName = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Lưu'),
                ),
              ],
            ),
    );
  }
}
