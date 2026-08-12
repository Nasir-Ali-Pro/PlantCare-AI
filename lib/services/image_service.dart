import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from camera or gallery and returns its compressed bytes and filename.
  /// Returns null if picking is cancelled or fails.
  static Future<UploadedImageInfo?> pickAndCompressImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile == null) return null;

      final String fileName = pickedFile.name;
      final Uint8List originalBytes = await pickedFile.readAsBytes();
      
      debugPrint("📸 Original size: ${(originalBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB");

      final Uint8List compressedBytes = await compressBytes(originalBytes);
      
      debugPrint("⚡ Compressed size: ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB");

      return UploadedImageInfo(
        bytes: compressedBytes,
        fileName: fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ? fileName : '$fileName.jpg',
      );
    } catch (e) {
      debugPrint("⚠️ Error picking/compressing image: $e");
      return null;
    }
  }

  /// Picks multiple images from gallery and returns a list of compressed image infos.
  static Future<List<UploadedImageInfo>> pickMultiAndCompressImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFiles.isEmpty) return [];

      final List<UploadedImageInfo> result = [];
      for (final file in pickedFiles) {
        final String fileName = file.name;
        final Uint8List originalBytes = await file.readAsBytes();
        
        debugPrint("📸 Multi-pick original size: ${(originalBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB");
        
        final Uint8List compressedBytes = await compressBytes(originalBytes);
        
        debugPrint("⚡ Multi-pick compressed size: ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB");

        result.add(UploadedImageInfo(
          bytes: compressedBytes,
          fileName: fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ? fileName : '$fileName.jpg',
        ));
      }
      return result;
    } catch (e) {
      debugPrint("⚠️ Error picking multiple images: $e");
      return [];
    }
  }

  /// Resizes and compresses image bytes to target 100KB - 200KB range
  static Future<Uint8List> compressBytes(Uint8List bytes, {int quality = 80}) async {
    if (kIsWeb) {
      // Pure Dart fallback with strict downscaling and compression for web to fit LocalStorage quota
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return bytes;

        // Resize strictly to max 600x600 pixels to minimize size while preserving aspect ratio
        img.Image resized = decoded;
        if (decoded.width > 600 || decoded.height > 600) {
          if (decoded.width > decoded.height) {
            resized = img.copyResize(decoded, width: 600);
          } else {
            resized = img.copyResize(decoded, height: 600);
          }
        }

        int currentQuality = 60;
        Uint8List compressed = Uint8List.fromList(img.encodeJpg(resized, quality: currentQuality));

        while (compressed.lengthInBytes > 50 * 1024 && currentQuality > 20) {
          currentQuality -= 10;
          compressed = Uint8List.fromList(img.encodeJpg(resized, quality: currentQuality));
        }
        return compressed;
      } catch (e) {
        debugPrint("⚠️ Web compression failed: $e");
        return bytes;
      }
    }

    // Skip if already in range for mobile (200KB)
    if (bytes.lengthInBytes <= 200 * 1024) {
      return bytes;
    } else {
      // Native compression using 'flutter_image_compress'
      try {
        int currentQuality = quality;
        Uint8List compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1024,
          minHeight: 1024,
          quality: currentQuality,
          keepExif: false,
          format: CompressFormat.jpeg,
        );

        while (compressed.lengthInBytes > 200 * 1024 && currentQuality > 30) {
          currentQuality -= 10;
          compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1024,
            minHeight: 1024,
            quality: currentQuality,
            keepExif: false,
            format: CompressFormat.jpeg,
          );
        }
        return compressed;
      } catch (e) {
        debugPrint("⚠️ Native compression failed, falling back to pure Dart: $e");
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded == null) return bytes;
          
          img.Image resized = decoded;
          if (decoded.width > 1200 || decoded.height > 1200) {
            resized = img.copyResize(decoded, width: 1024);
          }
          
          final compressed = img.encodeJpg(resized, quality: 70);
          return Uint8List.fromList(compressed);
        } catch (_) {
          return bytes;
        }
      }
    }
  }

  /// Uploads compressed image bytes to a Supabase bucket and returns the public URL.
  static Future<String?> uploadImage({
    required String bucketName,
    required Uint8List bytes,
    required String fileName,
    String? folderName,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Ensure file name is unique by prefixing UUID
      final uniqueId = const Uuid().v4();
      final cleanFileName = "${uniqueId}_$fileName";
      final uploadPath = folderName != null ? "$folderName/$cleanFileName" : cleanFileName;

      await supabase.storage.from(bucketName).uploadBinary(
        uploadPath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(uploadPath);
      debugPrint("🚀 Image successfully uploaded to $bucketName! Public URL: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("⚠️ Storage upload failed: $e");
      return null;
    }
  }

  /// Saves compressed bytes to the application documents directory for permanent local storage
  static Future<String> saveImageLocally(Uint8List bytes, String fileName) async {
    try {
      // In web, application documents directory is not supported.
      // But since web is fully online and doesn't run offline database in standard way,
      // we can return a data URL or blob URL if needed, or simply return an empty string/original fileName.
      // Since kIsWeb check guards this, we handle it:
      if (kIsWeb) {
        // Fallback for web: we can convert to base64 data URL to store it locally!
        // Storing as base64 string in the local DB is extremely standard and clean for offline web storage!
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      }

      final directory = await getApplicationDocumentsDirectory();
      // Ensure the directory exists
      final localDir = Directory('${directory.path}/garden_photos');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      final file = File('${localDir.path}/${const Uuid().v4()}_$fileName');
      await file.writeAsBytes(bytes);
      debugPrint("💾 Saved image locally to permanent storage: ${file.path}");
      return file.path;
    } catch (e) {
      debugPrint("⚠️ Failed to save image locally: $e");
      rethrow;
    }
  }

  /// Deletes a file from Supabase storage using its full public URL.
  static Future<void> deleteStorageFileByUrl(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.contains('/storage/v1/object/public/')) return;
    try {
      final supabase = Supabase.instance.client;
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex != -1 && publicIndex + 2 < pathSegments.length) {
        final bucketName = pathSegments[publicIndex + 1];
        final filePath = pathSegments.sublist(publicIndex + 2).join('/');

        await supabase.storage.from(bucketName).remove([filePath]);
        debugPrint("🗑️ Removed image from Supabase Storage ($bucketName): $filePath");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to delete storage file by URL ($imageUrl): $e");
    }
  }

  /// Deletes multiple files from Supabase storage given a list of public URLs.
  static Future<void> deleteStorageFilesByUrls(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteStorageFileByUrl(url);
    }
  }
}

class UploadedImageInfo {
  final Uint8List bytes;
  final String fileName;

  UploadedImageInfo({
    required this.bytes,
    required this.fileName,
  });
}
