import 'package:flutter/material.dart';

import 'data/local/database.dart';
import 'data/remote/api_client.dart';
import 'data/sync/pull_catalog.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/products/product_repository.dart';
import 'features/shifts/shift_repository.dart';

void main() {
  final database = AppDatabase();
  final apiClient = ApiClient();
  final repository = AuthRepository(
    dio: apiClient.dio,
    secureStorage: const SecureTokenStorage(),
    db: database,
  );
  final shiftRepository = ShiftRepository(dio: apiClient.dio, db: database);
  final productRepository = ProductRepository(database);
  final pullCatalog = PullCatalog(db: database, dio: apiClient.dio);
  runApp(
    PosApp(
      authRepository: repository,
      shiftRepository: shiftRepository,
      productRepository: productRepository,
      pullCatalog: pullCatalog,
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({
    super.key,
    required this.authRepository,
    required this.shiftRepository,
    required this.productRepository,
    required this.pullCatalog,
  });

  final AuthRepository authRepository;
  final ShiftRepository shiftRepository;
  final ProductRepository productRepository;
  final PullCatalog pullCatalog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Hoa POS',
      home: LoginPage(
        repository: authRepository,
        shiftRepository: shiftRepository,
        productRepository: productRepository,
        pullCatalog: pullCatalog,
      ),
    );
  }
}
