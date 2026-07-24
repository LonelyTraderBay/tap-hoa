import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

const _regularAsset = 'assets/fonts/NotoSans-Regular.ttf';
const _boldAsset = 'assets/fonts/NotoSans-Bold.ttf';

pw.Font? _regular;
pw.Font? _bold;
Future<void>? _loadFuture;

/// Loads Noto Sans TTF assets once for PDF text (Vietnamese diacritics).
Future<void> ensurePdfFontsLoaded() {
  return _loadFuture ??= _loadPdfFonts();
}

Future<void> _loadPdfFonts() async {
  final regularData = await rootBundle.load(_regularAsset);
  final boldData = await rootBundle.load(_boldAsset);
  _regular = pw.Font.ttf(regularData);
  _bold = pw.Font.ttf(boldData);
}

pw.Font get pdfFontRegular {
  final font = _regular;
  if (font == null) {
    throw StateError('PDF fonts not loaded; call ensurePdfFontsLoaded() first');
  }
  return font;
}

pw.Font get pdfFontBold {
  final font = _bold;
  if (font == null) {
    throw StateError('PDF fonts not loaded; call ensurePdfFontsLoaded() first');
  }
  return font;
}

@visibleForTesting
void resetPdfFontsForTesting() {
  _regular = null;
  _bold = null;
  _loadFuture = null;
}
