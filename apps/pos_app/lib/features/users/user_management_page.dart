import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const userRoleOptions = <String>['owner', 'store_manager', 'cashier'];

/// Nhãn tiếng Việt của vai trò theo spec §3.2.
String userRoleLabel(String? role) {
  switch (role) {
    case 'owner':
      return 'Chủ';
    case 'store_manager':
      return 'Quản lý điểm';
    case 'cashier':
      return 'Thu ngân';
    default:
      return role ?? '—';
  }
}

/// Thu ngân không được cấp quyền sổ kế toán / hóa đơn điện tử.
bool userRoleAllowsAccountingFlags(String? role) => role != 'cashier';

String userApiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    final status = error.response?.statusCode;
    if (status != null) {
      return '$fallback (mã $status)';
    }
  }
  return fallback;
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({
    super.key,
    required this.dio,
    required this.currentUserId,
  });

  final Dio dio;

  /// Id của người đang đăng nhập — dùng để nhận diện khi ai đó tự đổi mật
  /// khẩu của chính mình (so với đường quản trị đổi mật khẩu người khác),
  /// vì API bắt buộc `currentPassword` cho trường hợp tự đổi.
  final String currentUserId;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final storeResponse = await widget.dio.get<List<dynamic>>('/stores');
      final userResponse = await widget.dio.get<List<dynamic>>('/users');
      if (!mounted) return;
      setState(() {
        _stores = (storeResponse.data ?? [])
            .cast<Map<String, dynamic>>()
            .toList();
        _users = (userResponse.data ?? []).cast<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = userApiErrorMessage(
          error,
          'Không tải được danh sách nhân viên (cần online)',
        );
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _storeById(String storeId) {
    for (final store in _stores) {
      if (store['id'] == storeId) return store;
    }
    return null;
  }

  String _storeLabel(Object? storeIds) {
    final ids = storeIds is List ? storeIds : const [];
    if (ids.isEmpty) return 'Chưa gán điểm bán';
    return ids
        .map((id) => _storeById('$id')?['code'] as String? ?? '?')
        .join(', ');
  }

  Future<void> _openForm([Map<String, dynamic>? user]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            UserEditPage(dio: widget.dio, stores: _stores, user: user),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final active = user['active'] as bool? ?? true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.dio.patch<Map<String, dynamic>>(
        '/users/${user['id']}',
        data: {'active': !active},
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(active ? 'Đã ngưng hoạt động' : 'Đã kích hoạt lại'),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = userApiErrorMessage(
          error,
          'Không đổi được trạng thái nhân viên',
        ),
      );
    }
  }

  Future<void> _changePassword(Map<String, dynamic> user) async {
    final isSelf = '${user['id']}' == widget.currentUserId;
    final newPasswordController = TextEditingController();
    final currentPasswordController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<({String newPassword, String? currentPassword})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đổi mật khẩu · ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelf)
              TextField(
                controller: currentPasswordController,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
              ),
            if (isSelf) const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              autofocus: !isSelf,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop((
              newPassword: newPasswordController.text,
              currentPassword: isSelf ? currentPasswordController.text : null,
            )),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    newPasswordController.dispose();
    currentPasswordController.dispose();
    if (result == null) return;
    final password = result.newPassword;
    if (password.length < 6) {
      if (!mounted) return;
      setState(() => _message = 'Mật khẩu phải từ 6 ký tự');
      return;
    }
    if (isSelf && (result.currentPassword == null || result.currentPassword!.isEmpty)) {
      if (!mounted) return;
      setState(() => _message = 'Nhập mật khẩu hiện tại để xác nhận');
      return;
    }
    try {
      await widget.dio.patch<Map<String, dynamic>>(
        '/users/${user['id']}/password',
        data: {
          'password': password,
          if (isSelf) 'currentPassword': result.currentPassword,
        },
      );
      messenger.showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu')));
    } catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _message = userApiErrorMessage(error, 'Không đổi được mật khẩu'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Thêm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null) ...[
                  Text(_message!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
                if (_users.isEmpty && _message == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có nhân viên nào',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final user in _users)
                  Card(
                    child: ListTile(
                      title: Text('${user['name']}'),
                      subtitle: Text(
                        '${user['phone']} · ${userRoleLabel(user['role'] as String?)}\n'
                        '${_storeLabel(user['storeIds'])} · '
                        '${(user['active'] as bool? ?? true) ? 'Đang hoạt động' : 'Đã ngưng'}'
                        '${_permissionSuffix(user)}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Thao tác',
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              await _openForm(user);
                            case 'password':
                              await _changePassword(user);
                            case 'toggle':
                              await _toggleActive(user);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Sửa'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'password',
                            child: Text('Đổi mật khẩu'),
                          ),
                          PopupMenuItem<String>(
                            value: 'toggle',
                            child: Text(
                              (user['active'] as bool? ?? true)
                                  ? 'Ngưng hoạt động'
                                  : 'Kích hoạt lại',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _permissionSuffix(Map<String, dynamic> user) {
    final flags = <String>[
      if (user['canLedger'] as bool? ?? false) 'sổ kế toán',
      if (user['canEinvoice'] as bool? ?? false) 'HĐĐT',
    ];
    if (flags.isEmpty) return '';
    return ' · ${flags.join(', ')}';
  }
}

class UserEditPage extends StatefulWidget {
  const UserEditPage({
    super.key,
    required this.dio,
    required this.stores,
    this.user,
  });

  final Dio dio;
  final List<Map<String, dynamic>> stores;
  final Map<String, dynamic>? user;

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late String _role;
  late Set<String> _storeIds;
  late bool _canLedger;
  late bool _canEinvoice;
  late bool _active;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _phoneController = TextEditingController(text: user?['phone'] as String?);
    _nameController = TextEditingController(text: user?['name'] as String?);
    _passwordController = TextEditingController();
    _role = user?['role'] as String? ?? 'cashier';
    _storeIds = ((user?['storeIds'] as List<dynamic>?) ?? const [])
        .map((id) => '$id')
        .toSet();
    _canLedger = user?['canLedger'] as bool? ?? false;
    _canEinvoice = user?['canEinvoice'] as bool? ?? false;
    _active = user?['active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (!_isEdit && (phone.length < 8 || phone.length > 15)) {
      setState(() => _error = 'Số điện thoại phải có 8..15 chữ số');
      return;
    }
    if (name.isEmpty || name.length > 120) {
      setState(() => _error = 'Tên nhân viên phải dài 1..120 ký tự');
      return;
    }
    if (!_isEdit && password.length < 6) {
      setState(() => _error = 'Mật khẩu phải từ 6 ký tự');
      return;
    }
    if (_storeIds.isEmpty) {
      setState(() => _error = 'Chọn ít nhất một điểm bán');
      return;
    }

    final allowsFlags = userRoleAllowsAccountingFlags(_role);
    final canLedger = allowsFlags && _canLedger;
    final canEinvoice = allowsFlags && _canEinvoice;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await widget.dio.patch<Map<String, dynamic>>(
          '/users/${widget.user!['id']}',
          data: {
            'name': name,
            'role': _role,
            'storeIds': _storeIds.toList(),
            'canLedger': canLedger,
            'canEinvoice': canEinvoice,
            'active': _active,
          },
        );
      } else {
        await widget.dio.post<Map<String, dynamic>>(
          '/users',
          data: {
            'phone': phone,
            'name': name,
            'password': password,
            'role': _role,
            'storeIds': _storeIds.toList(),
            'canLedger': canLedger,
            'canEinvoice': canEinvoice,
          },
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Đã sửa nhân viên' : 'Đã thêm nhân viên'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userApiErrorMessage(
          error,
          'Lưu thất bại (kiểm tra số điện thoại trùng hoặc kết nối)',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowsFlags = userRoleAllowsAccountingFlags(_role);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _phoneController,
                enabled: !_isEdit,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Số điện thoại (đăng nhập)',
                  helperText: _isEdit ? 'Không đổi được số điện thoại' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: userRoleOptions
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(userRoleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _role = value ?? 'cashier';
                        if (!userRoleAllowsAccountingFlags(_role)) {
                          _canLedger = false;
                          _canEinvoice = false;
                        }
                      }),
              ),
              const SizedBox(height: 16),
              Text(
                'Điểm bán được làm việc',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (widget.stores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Chưa có điểm bán nào'),
                ),
              for (final store in widget.stores)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('${store['code']} · ${store['name']}'),
                  value: _storeIds.contains(store['id']),
                  onChanged: _busy
                      ? null
                      : (checked) => setState(() {
                          final id = '${store['id']}';
                          if (checked == true) {
                            _storeIds.add(id);
                          } else {
                            _storeIds.remove(id);
                          }
                        }),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quyền sổ kế toán'),
                subtitle: allowsFlags
                    ? null
                    : const Text('Thu ngân không được cấp quyền này'),
                value: _canLedger,
                onChanged: !allowsFlags || _busy
                    ? null
                    : (value) => setState(() => _canLedger = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quyền hóa đơn điện tử'),
                subtitle: allowsFlags
                    ? null
                    : const Text('Thu ngân không được cấp quyền này'),
                value: _canEinvoice,
                onChanged: !allowsFlags || _busy
                    ? null
                    : (value) => setState(() => _canEinvoice = value),
              ),
              if (_isEdit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang hoạt động'),
                  value: _active,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _active = value),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
