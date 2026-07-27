import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../products/product_repository.dart';
import '../reports/stock_on_hand_page.dart';
import '../reports/stock_on_hand_repository.dart';
import '../shifts/shift_repository.dart';
import 'allow_negative_stock_sheet.dart';
import 'inventory_service.dart';

class InventoryHubPage extends StatefulWidget {
  const InventoryHubPage({
    super.key,
    required this.db,
    required this.dio,
    required this.inventoryService,
    required this.productRepository,
    required this.stockOnHandRepository,
    required this.storeId,
    required this.role,
  });

  final AppDatabase db;
  final Dio dio;
  final InventoryService inventoryService;
  final ProductRepository productRepository;
  final StockOnHandRepository stockOnHandRepository;
  final String storeId;
  final String role;

  @override
  State<InventoryHubPage> createState() => _InventoryHubPageState();
}

class _PurchaseLineDraft {
  _PurchaseLineDraft({
    required this.productId,
    String qty = '1',
    String cost = '',
    this.unitCostVnd,
    this.maxQty,
  }) : qtyCtrl = TextEditingController(text: qty),
       costCtrl = TextEditingController(text: cost);

  String productId;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;
  final int? unitCostVnd;
  final Decimal? maxQty;

  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
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

  Future<List<InventoryLineInput>?> _showPurchaseLinesDialog({
    required String title,
    required List<ProductWithStock> products,
    required List<_PurchaseLineDraft> drafts,
    Widget? header,
    bool includeCost = false,
    bool canAddLines = false,
    bool allowZeroQty = false,
  }) async {
    if (products.isEmpty) {
      await _snack('Chưa có sản phẩm');
      return null;
    }
    final productById = {for (final product in products) product.id: product};
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (header != null) ...[header, const SizedBox(height: 12)],
                    for (var i = 0; i < drafts.length; i++)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              if (canAddLines)
                                DropdownButtonFormField<String>(
                                  initialValue: drafts[i].productId,
                                  decoration: const InputDecoration(
                                    labelText: 'Sản phẩm',
                                  ),
                                  items: [
                                    for (final p in products)
                                      DropdownMenuItem(
                                        value: p.id,
                                        child: Text('${p.name} (${p.qty})'),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setDialogState(() {
                                      drafts[i].productId = value;
                                    });
                                  },
                                )
                              else
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    productById[drafts[i].productId]?.name ??
                                        drafts[i].productId,
                                  ),
                                  subtitle: drafts[i].maxQty == null
                                      ? null
                                      : Text(
                                          'Còn ${formatInventoryQty(drafts[i].maxQty!)}',
                                        ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: drafts[i].qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Số lượng',
                                      ),
                                    ),
                                  ),
                                  if (includeCost) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: drafts[i].costCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Giá nhập dự kiến',
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (canAddLines && drafts.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          drafts.removeAt(i).dispose();
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Xóa dòng',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (canAddLines)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              drafts.add(
                                _PurchaseLineDraft(
                                  productId: products.first.id,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm dòng'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
      if (ok != true) return null;

      final seen = <String>{};
      final parsed = <InventoryLineInput>[];
      for (final draft in drafts) {
        final qtyText = draft.qtyCtrl.text.trim();
        final qty = qtyText.isEmpty && allowZeroQty
            ? Decimal.zero
            : Decimal.parse(qtyText);
        if (allowZeroQty && qty == Decimal.zero) {
          continue;
        }
        if (qty <= Decimal.zero) {
          throw const FormatException('invalid_qty');
        }
        if (draft.maxQty != null && qty > draft.maxQty!) {
          throw StateError('over_received');
        }
        if (!seen.add(draft.productId)) {
          throw StateError('duplicate_product');
        }
        final costText = draft.costCtrl.text.trim();
        parsed.add(
          InventoryLineInput(
            productId: draft.productId,
            qty: qty,
            unitCostVnd: includeCost
                ? (costText.isEmpty ? null : int.parse(costText))
                : draft.unitCostVnd,
          ),
        );
      }
      if (parsed.isEmpty) {
        throw StateError('empty_lines');
      }
      return parsed;
    } catch (_) {
      await _snack('Dòng hàng không hợp lệ');
      return null;
    } finally {
      for (final draft in drafts) {
        draft.dispose();
      }
    }
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
    final products = await widget.productRepository.listWithStock(
      widget.storeId,
    );
    if (!mounted || products.isEmpty) {
      await _snack('Chưa có sản phẩm');
      return;
    }
    final supplierCtrl = TextEditingController(text: 'NCC');
    final lines = await _showPurchaseLinesDialog(
      title: 'Tạo PO',
      products: products,
      drafts: [_PurchaseLineDraft(productId: products.first.id)],
      header: TextField(
        controller: supplierCtrl,
        decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
      ),
      includeCost: true,
      canAddLines: true,
    );
    final supplierName = supplierCtrl.text.trim();
    supplierCtrl.dispose();
    if (lines == null) return;
    if (supplierName.isEmpty) {
      await _snack('Nhập nhà cung cấp');
      return;
    }
    try {
      await widget.inventoryService.createPurchaseOrder(
        supplierName: supplierName,
        lines: lines,
      );
      await _snack('Đã tạo PO draft');
    } catch (e) {
      await _snack('Lỗi: $e');
    }
  }

  Future<void> _receivePurchaseOrder(PurchaseOrdersLocalData order) async {
    final poLines = await (widget.db.select(
      widget.db.purchaseOrderLinesLocal,
    )..where((l) => l.purchaseOrderId.equals(order.id))).get();
    final openLines = poLines
        .where((line) {
          return Decimal.parse(line.receivedQty) < Decimal.parse(line.qty);
        })
        .toList(growable: false);
    if (openLines.isEmpty) {
      await _snack('PO đã nhận đủ');
      return;
    }
    final products = await widget.productRepository.listWithStock(
      widget.storeId,
    );
    if (!mounted) return;
    final lines = await _showPurchaseLinesDialog(
      title: 'Nhận PO ${order.supplierName}',
      products: products,
      drafts: [
        for (final line in openLines)
          _PurchaseLineDraft(
            productId: line.productId,
            qty: formatInventoryQty(
              Decimal.parse(line.qty) - Decimal.parse(line.receivedQty),
            ),
            unitCostVnd: line.unitCostVnd,
            maxQty: Decimal.parse(line.qty) - Decimal.parse(line.receivedQty),
          ),
      ],
      allowZeroQty: true,
    );
    if (lines == null) return;
    try {
      await widget.inventoryService.receivePurchaseOrder(
        purchaseOrderId: order.id,
        lines: lines,
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
                initialValue: toStoreId,
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
          if (canTransfer)
            IconButton(
              tooltip: 'Cho phép âm tồn',
              icon: const Icon(Icons.exposure_outlined),
              onPressed: () => showAllowNegativeStockSheet(
                context,
                db: widget.db,
                dio: widget.dio,
                storeId: widget.storeId,
                role: widget.role,
              ),
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
