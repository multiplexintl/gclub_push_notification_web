import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

class ImageUtils {
  /// Encode image bytes to base64 data URI
  /// Returns null if encoding fails
  static String? encodeImageToBase64(Uint8List? imageBytes, {String? fileName}) {
    try {
      // Handle null/empty cases
      if (imageBytes == null || imageBytes.isEmpty) {
        log("ImageUtils.encode: No image bytes provided");
        return "null";
      }

      // Determine MIME type from filename or default to jpeg
      String mimeType = 'image/jpeg';
      if (fileName != null && fileName.isNotEmpty) {
        final extension = fileName.split('.').last.toLowerCase();
        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
        }
      }

      // Encode to base64
      final base64String = base64Encode(imageBytes);
      final dataUri = 'data:$mimeType;base64,$base64String';
      
      log("ImageUtils.encode: Success - ${imageBytes.length} bytes encoded to ${dataUri.length} chars");
      return dataUri;
      
    } catch (e) {
      log("ImageUtils.encode: Error - $e");
      return "null";
    }
  }

  /// Decode base64 data URI to image bytes
  /// Returns null if decoding fails
  static Uint8List? decodeBase64ToBytes(String? imageData) {
    try {
      // Handle null/empty cases
      if (imageData == null || imageData.isEmpty) {
        log("ImageUtils.decode: No image data provided");
        return null;
      }

      // Handle plain base64 string (without data URI prefix)
      String base64String = imageData;
      
      // If it's a data URI, extract the base64 part
      if (imageData.contains('base64,')) {
        final parts = imageData.split('base64,');
        if (parts.length != 2) {
          log("ImageUtils.decode: Invalid data URI format");
          return null;
        }
        base64String = parts[1];
      }

      // Remove any whitespace
      base64String = base64String.replaceAll(RegExp(r'\s'), '');
      
      if (base64String.isEmpty) {
        log("ImageUtils.decode: Empty base64 string");
        return null;
      }

      // Decode base64
      final bytes = base64Decode(base64String);
      log("ImageUtils.decode: Success - decoded to ${bytes.length} bytes");
      return bytes;
      
    } catch (e) {
      log("ImageUtils.decode: Error - $e");
      return null;
    }
  }
}
