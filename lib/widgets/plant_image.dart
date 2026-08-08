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
  Widget buildPlaceholderIcon() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
      child: const Center(
        child: Icon(Icons.local_florist_rounded, color: AppColors.primary, size: 24),
      ),
    );
  }

  if (path.isEmpty) {
    return buildPlaceholderIcon();
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
        errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
      );
    } catch (e) {
      debugPrint("⚠️ Failed to parse base64 image: $e");
      return buildPlaceholderIcon();
    }
  }

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
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
        errorWidget: (context, url, error) => buildPlaceholderIcon(),
      );
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
  } else {
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
  }
}

Widget buildPlantImageFile(dynamic file, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  Widget buildPlaceholderIcon() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
      child: const Center(
        child: Icon(Icons.local_florist_rounded, color: AppColors.primary, size: 24),
      ),
    );
  }

  if (file == null) {
    return buildPlaceholderIcon();
  }

  // If the file is passed as XFile or has a path
  final String path = file.path;

  if (path.isEmpty) {
    return buildPlaceholderIcon();
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
        errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
      );
    } catch (e) {
      debugPrint("⚠️ Failed to parse base64 image file: $e");
      return buildPlaceholderIcon();
    }
  }

  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
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
        errorWidget: (context, url, error) => buildPlaceholderIcon(),
      );
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
  } else {
    final File ioFile = file is File ? file : File(path);
    return Image.file(
      ioFile,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildPlaceholderIcon(),
    );
  }
}
