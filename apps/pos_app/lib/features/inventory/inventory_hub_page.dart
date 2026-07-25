import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../products/product_repository.dart';
import '../reports/stock_on_hand_page.dart';
import '../reports/stock_on_hand_repository.dart';
import '../shifts/shift_repository.dart';
import 'inventory_service.dart';

class InventoryHubPage extends StatefulWidget {
  const InventoryHubPage({
    super.key,
    required this.db,
    required this.inventoryService,
    required this.productRepository,
    required this.stockOnHandRepository,
    required this.storeId,
    required this.role,
  });

  final AppDatabase db;
  final InventoryService inventoryService;
  final ProductRepository productRepository;
  final StockOnHandRepository stockOnHandRepository;
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
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _snack(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ProductWithStock?> _pickProduct() async {
    final products = await widget.productRepository.listWithStock(
      widget.storeId,
    );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
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

  Future<void> _createPurchaseOrder() async {
    final product = await _pickProduct();
    if (product == null || !mounted) return;
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController();
    final supplierCtrl = TextEditingController(text: 'NCC');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo PO'),
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
              decoration: const InputDecoration(labelText: 'Số lượng đặt'),
            ),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá nhập dự kiến'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.inventoryService.createPurchaseOrder(
        supplierName: supplierCtrl.text,
        lines: [
          InventoryLineInput(
            productId: product.id,
            qty: Decimal.parse(qtyCtrl.text.trim()),
            unitCostVnd: int.tryParse(costCtrl.text.trim()),
          ),
        ],
      );
      await _snack('Đã tạo PO draft');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  Future<void> _receivePurchaseOrder(PurchaseOrdersLocalData order) async {
    final lines = await (widget.db.select(
      widget.db.purchaseOrderLinesLocal,
    )..where((l) => l.purchaseOrderId.equals(order.id))).get();
    final line = lines
        .where((l) => Decimal.parse(l.receivedQty) < Decimal.parse(l.qty))
        .firstOrNull;
    if (line == null) {
      await _snack('PO đã nhận đủ');
      return;
    }
    final remaining = Decimal.parse(line.qty) - Decimal.parse(line.receivedQty);
    final qtyCtrl = TextEditingController(text: formatInventoryQty(remaining));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nhận PO ${order.supplierName}'),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Số lượng nhận (còn ${formatInventoryQty(remaining)})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.inventoryService.receivePurchaseOrder(
        purchaseOrderId: order.id,
        lines: [
          InventoryLineInput(
            productId: line.productId,
            qty: Decimal.parse(qtyCtrl.text.trim()),
            unitCostVnd: line.unitCostVnd,
          ),
        ],
      );
      await _snack('Đã nhận PO');
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tạo'),
            ),
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

  Future<void> _openStockOnHand() async {
    List<StoreOption>? stores;
    if (widget.role == 'owner') {
      final rows = await widget.db.select(widget.db.storesLocal).get();
      stores = rows
          .map((s) => StoreOption(id: s.id, code: s.code, name: s.name))
          .toList();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockOnHandPage(
          repository: widget.stockOnHandRepository,
          storeId: widget.storeId,
          role: widget.role,
          stores: stores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canTransfer =
        widget.role == 'owner' || widget.role == 'store_manager';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho'),
        actions: [
          TextButton(
            onPressed: _openStockOnHand,
            child: const Text('Tồn hiện tại'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Chứng từ'),
            Tab(text: 'Đơn mua'),
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
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Tạo đơn mua (PO)'),
                onTap: _createPurchaseOrder,
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
          StreamBuilder<List<PurchaseOrdersLocalData>>(
            stream: widget.inventoryService.watchPurchaseOrders(widget.storeId),
            builder: (context, snap) {
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('Chưa có PO'));
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final o = rows[i];
                  return ListTile(
                    title: Text(o.supplierName),
                    subtitle: Text(o.status),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (o.status == 'draft')
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService
                                    .orderPurchaseOrder(o.id);
                                await _snack('Đã đặt PO');
                              } catch (e) {
                                await _snack('Lỗi: $e');
                              }
                            },
                            child: const Text('Đặt'),
                          ),
                        if (o.status == 'ordered' || o.status == 'partial')
                          TextButton(
                            onPressed: () => _receivePurchaseOrder(o),
                            child: const Text('Nhận'),
                          ),
                        if (o.status == 'draft' ||
                            o.status == 'ordered' ||
                            o.status == 'partial')
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService
                                    .closePurchaseOrder(o.id);
                                await _snack('Đã đóng PO');
                              } catch (e) {
                                await _snack('Lỗi: $e');
                              }
                            },
                            child: const Text('Đóng'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
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
                    title: Text(
                      '${t.fromStoreId.substring(0, 8)} → ${t.toStoreId.substring(0, 8)}',
                    ),
                    subtitle: Text(t.status),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (canTransfer && t.status == 'draft') ...[
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.inventoryService.approveTransfer(
                                  t.id,
                                );
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
                                await widget.inventoryService.rejectTransfer(
                                  t.id,
                                );
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
                                await widget.inventoryService.receiveTransfer(
                                  t.id,
                                );
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
