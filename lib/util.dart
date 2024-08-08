import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:ffi/ffi.dart';
import 'package:http/http.dart';
import 'package:win32/win32.dart';

void changeWallpaper(String path) {
  final Pointer<Utf16> buffer = path.toNativeUtf16();
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, buffer, 1);
  calloc.free(buffer);
}

(int width, int height) getWindowsScreenSize() {
  int width = GetSystemMetrics(SM_CXSCREEN);
  int height = GetSystemMetrics(SM_CYSCREEN);
  return (width, height);
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

Future<Uint8List> adjustWallpaperToScreen(Uint8List wallpaper) async {
  img.Image image = img.decodeJpg(wallpaper)!;
  var (screenWidth, screenHeight) = getWindowsScreenSize();
  
  img.Image blurImage;
  if (image.width < image.height) {
    int cropHeight = (image.width*screenHeight/screenWidth).round();
    blurImage = img.copyCrop(image, x: 0, y: ((image.height-cropHeight)/2).round(), width: image.width, height: cropHeight, antialias: false);
    blurImage = img.copyResize(blurImage, width: screenWidth, height: screenHeight);

    image = img.copyResize(image, maintainAspect: true, height: screenHeight);
    if (image.width > screenWidth) {
      image = img.copyResize(image, maintainAspect: true, width: screenWidth);
    }
  }
  else {
    int cropWidth = (image.height*screenWidth/screenHeight).round();
    blurImage = img.copyCrop(image, x: ((image.width-cropWidth)/2).round(), y: 0, width: cropWidth, height: image.height, antialias: false);
    blurImage = img.copyResize(blurImage, width: screenWidth, height: screenHeight);
    
    image = img.copyResize(image, maintainAspect: true, width: screenWidth);
    if (image.height > screenHeight) {
      image = img.copyResize(image, maintainAspect: true, height: screenHeight);
    }
  }

  blurImage = img.gaussianBlur(blurImage, radius: 45);

  image = img.compositeImage(blurImage, image, center: true);

  return img.encodeJpg(image);
}

