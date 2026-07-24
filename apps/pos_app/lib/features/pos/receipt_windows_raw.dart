import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

/// Sends raw ESC/POS bytes to a Windows printer by name.
/// Returns false on non-Windows or on Win32 failure.
Future<bool> sendRawToWindowsPrinter(
  String printerName,
  Uint8List bytes,
) async {
  if (kIsWeb || !Platform.isWindows) return false;
  if (printerName.trim().isEmpty || bytes.isEmpty) return false;

  final namePtr = printerName.toNativeUtf16();
  final phPrinter = calloc<HANDLE>();
  final written = calloc<DWORD>();
  final dataPtr = calloc<Uint8>(bytes.length);
  Pointer<Utf16>? docNamePtr;
  Pointer<Utf16>? dataTypePtr;
  Pointer<DOC_INFO_1>? docInfo;

  try {
    if (OpenPrinter(namePtr, phPrinter, nullptr) == FALSE) {
      return false;
    }
    final hPrinter = phPrinter.value;

    docNamePtr = 'POS Receipt'.toNativeUtf16();
    dataTypePtr = 'RAW'.toNativeUtf16();
    docInfo = calloc<DOC_INFO_1>()
      ..ref.pDocName = docNamePtr
      ..ref.pOutputFile = nullptr
      ..ref.pDatatype = dataTypePtr;

    final job = StartDocPrinter(hPrinter, 1, docInfo.cast());
    if (job <= 0) {
      ClosePrinter(hPrinter);
      return false;
    }
    if (StartPagePrinter(hPrinter) == FALSE) {
      EndDocPrinter(hPrinter);
      ClosePrinter(hPrinter);
      return false;
    }

    dataPtr.asTypedList(bytes.length).setAll(0, bytes);
    final ok = WritePrinter(hPrinter, dataPtr, bytes.length, written) != FALSE;
    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);
    return ok && written.value == bytes.length;
  } catch (e, st) {
    debugPrint('sendRawToWindowsPrinter failed: $e\n$st');
    return false;
  } finally {
    calloc.free(namePtr);
    calloc.free(phPrinter);
    calloc.free(written);
    calloc.free(dataPtr);
    if (docInfo != null) calloc.free(docInfo);
    if (docNamePtr != null) calloc.free(docNamePtr);
    if (dataTypePtr != null) calloc.free(dataTypePtr);
  }
}
