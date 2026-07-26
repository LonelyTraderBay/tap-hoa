import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
