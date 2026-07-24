import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../products/product_repository.dart';
import 'inventory_service.dart';

class InventoryHubPage extends StatefulWidget {
  const InventoryHubPage({
    super.key,
    required this.db,
    required this.inventoryService,
    required this.productRepository,
    required this.storeId,
    required this.role,
  });

  final AppDatabase db;
  final InventoryService inventoryService;
  final ProductRepository productRepository;
  final String storeId;
  final String role;

  @override
  State<InventoryHubPage> createState() => _InventoryHubPageState();
}

class _InventoryHubPageState extends State<InventoryHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _snack(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ProductWithStock?> _pickProduct() async {
    final products = await widget.productRepository.listWithStock(widget.storeId);
    if (!mounted || products.isEmpty) {
      await _snack('Chưa có sản phẩm');
      return null;
    }
    return showDialog<ProductWithStock>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn sản phẩm'),
        children: [
          for (final p in products)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text('${p.name} (${p.qty})'),
            ),
        ],
      ),
    );
  }

  Future<void> _createPurchase() async {
    final product = await _pickProduct();
    if (product == null || !mounted) return;
    final qtyCtrl = TextEditingController(text: '1');
    final supplierCtrl = TextEditingController(text: 'NCC');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập NCC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: supplierCtrl,
              decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
            ),
            Text(product.name),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.inventoryService.recordPurchase(
        supplierName: supplierCtrl.text,
        lines: [
          InventoryLineInput(
            productId: product.id,
            qty: Decimal.parse(qtyCtrl.text.trim()),
          ),
        ],
      );
      await _snack('Đã ghi phiếu nhập');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  Future<void> _createWastage() async {
    final product = await _pickProduct();
    if (product == null || !mounted) return;
    final qtyCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất hủy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.inventoryService.recordWastage(
        reasonCode: 'spoilage',
        lines: [
          InventoryLineInput(
            productId: product.id,
            qty: Decimal.parse(qtyCtrl.text.trim()),
          ),
        ],
      );
      await _snack('Đã ghi xuất hủy');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  Future<void> _createStocktake() async {
    final product = await _pickProduct();
    if (product == null || !mounted) return;
    final countedCtrl = TextEditingController(text: product.qty);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm kê'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${product.name} — hệ thống: ${product.qty}'),
            TextField(
              controller: countedCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Đếm thực tế'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final systemQty = Decimal.parse(product.qty);
      final countedQty = Decimal.parse(countedCtrl.text.trim());
      await widget.inventoryService.recordStocktake(
        lines: [
          InventoryLineInput(
            productId: product.id,
            qty: countedQty,
            systemQty: systemQty,
            countedQty: countedQty,
          ),
        ],
      );
      await _snack('Đã ghi kiểm kê');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  Future<void> _createTransfer() async {
    final stores = await widget.db.select(widget.db.storesLocal).get();
    final others = stores.where((s) => s.id != widget.storeId).toList();
    if (others.isEmpty) {
      await _snack('Cần ít nhất 2 điểm bán');
      return;
    }
    final product = await _pickProduct();
    if (product == null || !mounted) return;
    final qtyCtrl = TextEditingController(text: '1');
    var toStoreId = others.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Chuyển kho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use — need controlled value inside StatefulBuilder
                value: toStoreId,
                items: [
                  for (final s in others)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setLocal(() => toStoreId = v ?? toStoreId),
                decoration: const InputDecoration(labelText: 'Điểm đích'),
              ),
              Text(product.name),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số lượng'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await widget.inventoryService.createTransfer(
        toStoreId: toStoreId,
        lines: [
          InventoryLineInput(
            productId: product.id,
            qty: Decimal.parse(qtyCtrl.text.trim()),
          ),
        ],
      );
      await _snack('Đã tạo phiếu chuyển (draft)');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTransfer =
        widget.role == 'owner' || widget.role == 'store_manager';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Chứng từ'),
            Tab(text: 'Chuyển kho'),
            Tab(text: 'Lịch sử tồn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.move_to_inbox_outlined),
                title: const Text('Nhập NCC'),
                onTap: _createPurchase,
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xuất hủy / hao hụt'),
                onTap: _createWastage,
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Kiểm kê'),
                onTap: _createStocktake,
              ),
              if (canTransfer)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Tạo chuyển kho'),
                  onTap: _createTransfer,
                ),
            ],
          ),
          StreamBuilder<List<StockTransfersLocalData>>(
            stream: widget.inventoryService.watchTransfers(widget.storeId),
            builder: (context, snap) {
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('Chưa có phiếu chuyển'));
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final t = rows[i];
                  return ListTile(
                    title: Text('${t.fromStoreId.substring(0, 8)} → ${t.toStoreId.substring(0, 8)}'),
                    subtitle: Text(t.status),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (canTransfer && t.status == 'draft') ...[
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService.approveTransfer(t.id);
                                await _snack('Đã duyệt');
                              } catch (e) {
                                await _snack('Lỗi: $e');
                              }
                            },
                            child: const Text('Duyệt'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService.rejectTransfer(t.id);
                                await _snack('Đã từ chối');
                              } catch (e) {
                                await _snack('Lỗi: $e');
                              }
                            },
                            child: const Text('Từ chối'),
                          ),
                        ],
                        if (t.status == 'approved' &&
                            (t.toStoreId == widget.storeId ||
                                widget.role == 'owner'))
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService.receiveTransfer(t.id);
                                await _snack('Đã nhận hàng');
                              } catch (e) {
                                await _snack('Lỗi: $e');
                              }
                            },
                            child: const Text('Nhận'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          StreamBuilder<List<StockMovementsLocalData>>(
            stream: widget.inventoryService.watchMovements(widget.storeId),
            builder: (context, snap) {
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('Chưa có lịch sử tồn'));
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final m = rows[i];
                  return ListTile(
                    title: Text('${m.docType}: ${m.qtyDelta}'),
                    subtitle: Text(
                      'SP ${m.productId.substring(0, 8)} · sau = ${m.balanceAfter}',
                    ),
                    trailing: Text(
                      m.clientCreatedAt.toLocal().toString().substring(0, 16),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
