import 'package:flutter/material.dart';

import 'data/local/database.dart';
import 'data/remote/api_client.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';

void main() {
  final database = AppDatabase();
  final repository = AuthRepository(
    dio: ApiClient().dio,
    secureStorage: const SecureTokenStorage(),
    db: database,
  );
  runApp(PosApp(authRepository: repository));
}

class PosApp extends StatelessWidget {
  const PosApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Hoa POS',
      home: LoginPage(repository: authRepository),
    );
  }
}
