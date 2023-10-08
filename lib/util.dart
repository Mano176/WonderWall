import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart';
import 'package:win32/win32.dart';

void changeWallpaper(String path) {
  final Pointer<Utf16> buffer = path.toNativeUtf16();
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, buffer, 1);
  calloc.free(buffer);
}

Future<Map<String, dynamic>> sendGetRequest(String url, Map<String, String> params) async {
  String paramString = "";
  params.forEach((key, value) {
    paramString += "$key=$value&";
  });
  return jsonDecode((await get(Uri.parse("$url?$paramString"))).body);
}

Future<void> saveTempFile(List<int> data, String path) async {
  File file = File(path);
  await file.create(recursive: true);
  await file.writeAsBytes(data);
}
