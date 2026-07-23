import 'package:flutter/material.dart';

import '../../data/sync/pull_catalog.dart';
import 'product_repository.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.repository,
    required this.pullCatalog,
    required this.storeId,
  });

  final ProductRepository repository;
  final PullCatalog pullCatalog;
  final String storeId;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  bool _isPulling = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _pull();
  }

  Future<void> _pull() async {
    setState(() {
      _isPulling = true;
      _message = null;
    });
    try {
      await widget.pullCatalog.pullCatalog(widget.storeId);
      if (!mounted) return;
      setState(() => _message = 'Đã đồng bộ danh mục');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Đồng bộ thất bại');
    } finally {
      if (mounted) {
        setState(() => _isPulling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hàng hóa'),
        actions: [
          IconButton(
            onPressed: _isPulling ? null : _pull,
            icon: _isPulling
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_message!, textAlign: TextAlign.center),
            ),
          Expanded(
            child: StreamBuilder<List<ProductWithStock>>(
              stream: widget.repository.watchByStore(widget.storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Chưa có hàng hóa'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.sku} · ${item.unit}'),
                      trailing: Text('Tồn: ${item.qty}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
