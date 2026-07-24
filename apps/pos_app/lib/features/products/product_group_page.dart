import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'product_repository.dart';
import 'product_service.dart';

class ProductGroupPage extends StatefulWidget {
  const ProductGroupPage({
    super.key,
    required this.repository,
    required this.groupService,
  });

  final ProductRepository repository;
  final ProductGroupService groupService;

  @override
  State<ProductGroupPage> createState() => _ProductGroupPageState();
}

class _ProductGroupPageState extends State<ProductGroupPage> {
  String? _message;

  Future<void> _openForm({ProductGroupRow? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final sortController = TextEditingController(
      text: (existing?.sortOrder ?? 0).toString(),
    );
    var active = existing?.active ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Thêm nhóm hàng' : 'Sửa nhóm hàng',
                    style: Theme.of(ctx).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên nhóm *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sortController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Thứ tự'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang dùng'),
                    value: active,
                    onChanged: (v) => setModal(() => active = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final sort = int.tryParse(sortController.text.trim()) ?? 0;
                      await widget.groupService.upsert(
                        id: existing?.id,
                        name: name,
                        sortOrder: sort,
                        active: active,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop(true);
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    sortController.dispose();
    if (!mounted) return;
    if (saved == true) {
      setState(() => _message = existing == null ? 'Đã thêm nhóm' : 'Đã cập nhật nhóm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhóm hàng')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhóm'),
      ),
      body: Column(
        children: [
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_message!, textAlign: TextAlign.center),
            ),
          Expanded(
            child: StreamBuilder<List<ProductGroupRow>>(
              stream: widget.repository.watchGroups(activeOnly: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Center(child: Text('Chưa có nhóm hàng'));
                }
                return ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    return ListTile(
                      title: Text(g.name),
                      subtitle: Text('Thứ tự ${g.sortOrder}'),
                      trailing: Text(
                        g.active ? 'Đang dùng' : 'Ẩn',
                        style: TextStyle(
                          color: g.active ? null : Colors.grey,
                        ),
                      ),
                      onTap: () => _openForm(existing: g),
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
