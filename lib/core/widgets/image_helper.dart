import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Dynamically resolves a string containing a photo (URL, Base64, or Local File path)
/// to a Flutter [ImageProvider].
ImageProvider getUserImageProvider(String url) {
  final cleanUrl = url.trim();
  if (cleanUrl.isEmpty) {
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200');
  }

  if (cleanUrl.startsWith('data:image/') && cleanUrl.contains('base64,')) {
    final base64String = cleanUrl.split('base64,').last;
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (_) {}
  } else if (cleanUrl.startsWith('base64:')) {
    final base64String = cleanUrl.substring(7);
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (_) {}
  } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    return NetworkImage(cleanUrl);
  }

  // Local File check for pickImage output
  try {
    final filePath = cleanUrl.startsWith('file://') ? cleanUrl.substring(7) : cleanUrl;
    final file = File(filePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}

  // Fallback try base64 decode if raw string
  try {
    return MemoryImage(base64Decode(cleanUrl));
  } catch (_) {}

  return NetworkImage(cleanUrl);
}

/// Dynamically resolves a string containing a photo to an [Image] or network image [Widget].
Widget getUserImageWidget(
  String url, {
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  final cleanUrl = url.trim();
  if (cleanUrl.isEmpty) {
    return Image.network(
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500',
      fit: fit,
    );
  }

  if (cleanUrl.startsWith('data:image/') && cleanUrl.contains('base64,')) {
    final base64String = cleanUrl.split('base64,').last;
    try {
      return Image.memory(base64Decode(base64String), fit: fit);
    } catch (_) {}
  } else if (cleanUrl.startsWith('base64:')) {
    final base64String = cleanUrl.substring(7);
    try {
      return Image.memory(base64Decode(base64String), fit: fit);
    } catch (_) {}
  } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    return Image.network(
      cleanUrl,
      fit: fit,
      loadingBuilder: placeholder != null
          ? (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder;
            }
          : null,
      errorBuilder: errorWidget != null
          ? (context, error, stackTrace) => errorWidget
          : null,
    );
  }

  try {
    final filePath = cleanUrl.startsWith('file://') ? cleanUrl.substring(7) : cleanUrl;
    final file = File(filePath);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }
  } catch (_) {}

  try {
    return Image.memory(base64Decode(cleanUrl), fit: fit);
  } catch (_) {}

  return Image.network(
    cleanUrl,
    fit: fit,
    errorBuilder: errorWidget != null ? (context, error, stackTrace) => errorWidget : null,
  );
}

/// Decodes, resizes, and converts a local image to a Base64 string to bypass Firebase Storage.
Future<String> compressAndEncodeImage(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  
  final ui.Codec codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 160,
  );
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ui.Image image = frameInfo.image;
  
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to compress image');
  }
  
  final Uint8List pngBytes = byteData.buffer.asUint8List();
  final String base64String = base64Encode(pngBytes);
  return 'base64:$base64String';
}
