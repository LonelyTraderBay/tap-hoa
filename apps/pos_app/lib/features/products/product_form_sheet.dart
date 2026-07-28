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
  final _sellUnitController = TextEditingController();
  final _packSizeController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _costController = TextEditingController();
  final _initialQtyController = TextEditingController(text: '0');
  final _minQtyController = TextEditingController(text: '0');

  bool _isWeighted = false;
  bool _active = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _groupId;
  String _kind = 'normal';
  List<ProductGroupRow> _groups = [];
  List<({String componentProductId, String qtyBase, String name})> _components =
      [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    if (widget.existing != null) {
      _loadExisting();
    }
  }

  Future<void> _loadGroups() async {
    final groups = await widget.repository.watchGroups().first;
    if (!mounted) return;
    setState(() => _groups = groups);
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
    _sellUnitController.text = data.sellUnit ?? '';
    _packSizeController.text = data.packSize ?? '';
    _basePriceController.text = data.basePriceVnd.toString();
    _costController.text = data.costVnd.toString();
    _minQtyController.text = data.minQty;
    setState(() {
      _isWeighted = data.isWeighted;
      _active = data.active;
      _groupId = data.groupId;
      _kind = data.kind;
      _components = data.components;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _sellUnitController.dispose();
    _packSizeController.dispose();
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

    if (_kind == 'combo' && _components.isEmpty) {
      setState(() => _error = 'Combo cần ít nhất 1 thành phần');
      return;
    }

    if (widget.isCreate && initialQty.isEmpty) {
      setState(() => _error = 'Nhập tồn ban đầu');
      return;
    }
    if (minQty.isEmpty) {
      setState(() => _error = 'Nhập tồn tối thiểu');
      return;
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
          sellUnit: _sellUnitController.text.trim().isEmpty
              ? null
              : _sellUnitController.text.trim(),
          packSize: _packSizeController.text.trim().isEmpty
              ? null
              : _packSizeController.text.trim(),
          kind: _kind,
          groupId: _groupId,
          isWeighted: _isWeighted,
          basePriceVnd: basePrice,
          costVnd: cost,
          active: _active,
          initialQty: initialQty,
          minQty: minQty,
          components: [
            for (final c in _components)
              ComboComponentInput(
                componentProductId: c.componentProductId,
                qtyBase: c.qtyBase,
              ),
          ],
        );
      } else {
        await widget.productService.update(
          id: widget.existing!.id,
          storeId: widget.storeId,
          sku: sku,
          barcode: barcode.isEmpty ? null : barcode,
          name: name,
          unit: unit,
          sellUnit: _sellUnitController.text.trim().isEmpty
              ? null
              : _sellUnitController.text.trim(),
          packSize: _packSizeController.text.trim().isEmpty
              ? null
              : _packSizeController.text.trim(),
          kind: _kind,
          groupId: _groupId,
          isWeighted: _isWeighted,
          basePriceVnd: basePrice,
          costVnd: cost,
          active: _active,
          minQty: minQty,
          components: [
            for (final c in _components)
              ComboComponentInput(
                componentProductId: c.componentProductId,
                qtyBase: c.qtyBase,
              ),
          ],
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message == 'invalid_combo'
            ? 'Combo cần ít nhất 1 thành phần'
            : 'Lưu thất bại';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addComponent() async {
    final products = await widget.repository.watchByStore(widget.storeId).first;
    final selfId = widget.existing?.id;
    final available = products
        .where(
          (p) =>
              p.id != selfId &&
              p.kind != 'combo' &&
              !_components.any((c) => c.componentProductId == p.id),
        )
        .toList();
    if (!mounted) return;
    if (available.isEmpty) {
      setState(() => _error = 'Không còn sản phẩm để thêm vào combo');
      return;
    }
    final picked = await showDialog<ProductWithStock>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn thành phần'),
        children: [
          for (final p in available)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(p),
              child: Text('${p.name} (${p.sku})'),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final qtyController = TextEditingController(text: '1');
    final qty = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Số lượng ${picked.name}'),
        content: TextField(
          controller: qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Qty (đơn vị gốc)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(qtyController.text.trim()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    qtyController.dispose();
    if (qty == null || qty.isEmpty || !mounted) return;
    final parsed = double.tryParse(qty);
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Số lượng thành phần không hợp lệ');
      return;
    }
    setState(() {
      _error = null;
      _components = [
        ..._components,
        (
          componentProductId: picked.id,
          qtyBase: qty,
          name: picked.name,
        ),
      ];
    });
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
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị cơ sở *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sellUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị bán (vd thùng)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _packSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Hệ số quy đổi (vd 24)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _groupId,
                    decoration: const InputDecoration(labelText: 'Nhóm hàng'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Không nhóm —'),
                      ),
                      ..._groups.map(
                        (g) => DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(g.name),
                        ),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (v) => setState(() => _groupId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    decoration: const InputDecoration(labelText: 'Loại'),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Thường')),
                      DropdownMenuItem(value: 'combo', child: Text('Combo')),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (v) => setState(() => _kind = v ?? 'normal'),
                  ),
                  if (_kind == 'combo') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Thành phần combo',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_components.isEmpty)
                      Text(
                        'Chưa có thành phần — bắt buộc ≥1 khi lưu',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    for (var i = 0; i < _components.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_components[i].name),
                        subtitle: Text('Qty: ${_components[i].qtyBase}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                    _components = [
                                      for (var j = 0;
                                          j < _components.length;
                                          j++)
                                        if (j != i) _components[j],
                                    ];
                                  }),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _addComponent,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thành phần'),
                    ),
                  ],
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
                  ],
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
