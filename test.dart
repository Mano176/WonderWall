import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  String path = "C:\\Users\\manos\\Desktop\\test.jpg";

  final Pointer<Utf16> buffer = path.toNativeUtf16();
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, buffer, 1);
  calloc.free(buffer);
}
