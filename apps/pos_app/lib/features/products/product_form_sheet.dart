import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'barcode_label.dart';
import 'product_repository.dart';
import 'product_service.dart';

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    super.key,
    required this.productService,
    required this.repository,
    required this.storeId,
    this.existing,
  });

  final ProductService productService;
  final ProductRepository repository;
  final String storeId;
  final ProductWithStock? existing;

  bool get isCreate => existing == null;

  static Future<bool> show(
    BuildContext context, {
    required ProductService productService,
    required ProductRepository repository,
    required String storeId,
    ProductWithStock? existing,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFormSheet(
        productService: productService,
        repository: repository,
        storeId: storeId,
        existing: existing,
      ),
    );
    return result ?? false;
  }

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _costController = TextEditingController();
  final _initialQtyController = TextEditingController(text: '0');
  final _minQtyController = TextEditingController(text: '0');

  bool _isWeighted = false;
  bool _active = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final data = await widget.repository.getForEdit(
      widget.existing!.id,
      widget.storeId,
    );
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _isLoading = false;
        _error = 'Không tìm thấy sản phẩm';
      });
      return;
    }
    _skuController.text = data.sku;
    _barcodeController.text = data.barcode ?? '';
    _nameController.text = data.name;
    _unitController.text = data.unit;
    _basePriceController.text = data.basePriceVnd.toString();
    _costController.text = data.costVnd.toString();
    setState(() {
      _isWeighted = data.isWeighted;
      _active = data.active;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _basePriceController.dispose();
    _costController.dispose();
    _initialQtyController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _printLabel() async {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final barcode = _barcodeController.text.trim();
    final basePrice = int.tryParse(_basePriceController.text.trim()) ?? 0;

    if (name.isEmpty || (barcode.isEmpty && sku.isEmpty)) {
      setState(() => _error = 'Cần tên và mã vạch hoặc SKU để in tem');
      return;
    }

    await promptAndPrintProductLabel(
      context,
      title: name,
      basePriceVnd: basePrice,
      barcode: barcode,
      sku: sku,
    );
  }

  Future<void> _save() async {
    final sku = _skuController.text.trim();
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    if (sku.isEmpty || name.isEmpty || unit.isEmpty) {
      setState(() => _error = 'Nhập đủ SKU, tên và đơn vị');
      return;
    }

    final basePrice = int.tryParse(_basePriceController.text.trim());
    if (basePrice == null || basePrice < 0) {
      setState(() => _error = 'Giá bán không hợp lệ');
      return;
    }

    final cost = int.tryParse(_costController.text.trim()) ?? 0;
    if (cost < 0) {
      setState(() => _error = 'Giá vốn không hợp lệ');
      return;
    }

    final barcode = _barcodeController.text.trim();
    final initialQty = _initialQtyController.text.trim();
    final minQty = _minQtyController.text.trim();

    if (widget.isCreate) {
      if (initialQty.isEmpty || minQty.isEmpty) {
        setState(() => _error = 'Nhập tồn ban đầu và tồn tối thiểu');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (widget.isCreate) {
        await widget.productService.create(
          storeId: widget.storeId,
          sku: sku,
          barcode: barcode.isEmpty ? null : barcode,
          name: name,
          unit: unit,
          isWeighted: _isWeighted,
          basePriceVnd: basePrice,
          costVnd: cost,
          active: _active,
          initialQty: initialQty,
          minQty: minQty,
        );
      } else {
        await widget.productService.update(
          id: widget.existing!.id,
          storeId: widget.storeId,
          sku: sku,
          barcode: barcode.isEmpty ? null : barcode,
          name: name,
          unit: unit,
          isWeighted: _isWeighted,
          basePriceVnd: basePrice,
          costVnd: cost,
          active: _active,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isCreate ? 'Thêm hàng hóa' : 'Sửa hàng hóa',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU *'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(labelText: 'Mã vạch'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Đơn vị *'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cân ký'),
                    value: _isWeighted,
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _isWeighted = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _basePriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Giá bán (VND) *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Giá vốn (VND)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang bán'),
                    value: _active,
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _active = value),
                  ),
                  if (widget.isCreate) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _initialQtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tồn ban đầu',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _minQtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tồn tối thiểu',
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _printLabel,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('In tem'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _save,
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu'),
                  ),
                ],
              ),
            ),
    );
  }
}
