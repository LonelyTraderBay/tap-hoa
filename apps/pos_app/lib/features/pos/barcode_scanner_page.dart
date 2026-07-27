import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Whether the camera-based barcode scanner (`PosBarcodeScannerPage`, backed
/// by `mobile_scanner`) can run on this platform. `mobile_scanner` only
/// supports Android/iOS — desktop/web have no camera plugin backing here.
bool posCameraBarcodeScannerAvailable(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

/// Shared entry point for the camera barcode scanner — pushes
/// [PosBarcodeScannerPage] and returns the scanned raw value (or `null` if
/// the user backed out without a detection). Reused by both the checkout
/// cart flow (`PosPage._scanBarcode`) and the inventory "quét mã xem tồn"
/// quick-check flow (`InventoryHubPage`) so there is exactly one place that
/// owns the camera/scanner widget wiring.
Future<String?> openCameraBarcodeScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
  );
}

class PosBarcodeScannerPage extends StatefulWidget {
  const PosBarcodeScannerPage({super.key});

  @override
  State<PosBarcodeScannerPage> createState() => _PosBarcodeScannerPageState();
}

class _PosBarcodeScannerPageState extends State<PosBarcodeScannerPage> {
  late final MobileScannerController _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) {
        continue;
      }

      _hasDetected = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét barcode')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Đưa barcode vào khung camera. POS sẽ tự thêm nếu barcode khớp đúng 1 hàng.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
