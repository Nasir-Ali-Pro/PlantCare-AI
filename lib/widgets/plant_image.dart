import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'dart:convert';
import '../core/theme/app_colors.dart';

Widget _buildShimmerPlaceholder({double? width, double? height}) {
  return Shimmer.fromColors(
    baseColor: AppColors.surfaceHighlight, // Premium botanical dark green base
    highlightColor: AppColors.borderLight, // Lighter sage green highlight
    child: Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: Colors.white,
    ),
  );
}

Widget buildPlantImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (path.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.white.withValues(alpha: 0.04),
      child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24),
    );
  }

  if (path.startsWith('data:')) {
    try {
      final String base64Str = path.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.white.withValues(alpha: 0.04),
          child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Failed to parse base64 image: $e");
      return Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      );
    }
  }

  final bool isNetwork = path.startsWith('http') || path.startsWith('https');

  if (kIsWeb || isNetwork || path.startsWith('blob:')) {
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmerPlaceholder(width: width, height: height),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.white.withValues(alpha: 0.04),
          child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
        ),
      );
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      ),
    );
  } else {
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      ),
    );
  }
}

Widget buildPlantImageFile(dynamic file, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (file == null) {
    return Container(
      width: width,
      height: height,
      color: Colors.white.withValues(alpha: 0.04),
      child: const Icon(Icons.image_not_supported_rounded, color: Colors.white24),
    );
  }

  // If the file is passed as XFile or has a path
  final String path = file.path;
  
  if (path.startsWith('data:')) {
    try {
      final String base64Str = path.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.white.withValues(alpha: 0.04),
          child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Failed to parse base64 image file: $e");
      return Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      );
    }
  }

  final bool isNetwork = path.startsWith('http') || path.startsWith('https');

  if (kIsWeb || isNetwork || path.startsWith('blob:')) {
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmerPlaceholder(width: width, height: height),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.white.withValues(alpha: 0.04),
          child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
        ),
      );
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      ),
    );
  } else {
    final File ioFile = file is File ? file : File(path);
    return Image.file(
      ioFile,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
      ),
    );
  }
}
