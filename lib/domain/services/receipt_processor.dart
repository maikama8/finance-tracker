import 'dart:io';
import '../value_objects/receipt_data.dart';

/// Service for processing receipt images
/// 
/// Handles storage, retrieval, and OCR extraction of receipt images.
/// Validates image format (JPEG/PNG) and size (≤10MB).
/// 
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**
abstract class ReceiptProcessor {
  /// Store a receipt image with compression
  /// 
  /// Validates that the image is JPEG or PNG format and ≤10MB.
  /// Compresses the image if needed to optimize storage.
  /// 
  /// Returns the unique image ID for later retrieval.
  /// Throws [InvalidImageFormatException] if format is not JPEG/PNG.
  /// Throws [ImageTooLargeException] if size exceeds 10MB.
  /// 
  /// **Validates: Requirements 5.1, 5.5**
  Future<String> storeReceiptImage(File image);

  /// Extract data from receipt image using OCR
  /// 
  /// Attempts to extract amount, date, merchant name, and currency.
  /// Returns null if OCR service is unavailable or extraction fails.
  /// Returns [ReceiptData] with confidence score if successful.
  /// 
  /// **Validates: Requirements 5.2, 5.3**
  Future<ReceiptData?> extractData(File image);

  /// Retrieve a stored receipt image by ID
  /// 
  /// Returns the image file if found, null otherwise.
  Future<File?> getReceiptImage(String imageId);

  /// Delete a stored receipt image by ID
  /// 
  /// Removes the image from storage.
  Future<void> deleteReceiptImage(String imageId);
}

/// Exception thrown when image format is not JPEG or PNG
class InvalidImageFormatException implements Exception {
  final String message;
  InvalidImageFormatException(this.message);
  
  @override
  String toString() => 'InvalidImageFormatException: $message';
}

/// Exception thrown when image size exceeds 10MB
class ImageTooLargeException implements Exception {
  final String message;
  final int sizeInBytes;
  final int maxSizeInBytes;
  
  ImageTooLargeException(this.message, this.sizeInBytes, this.maxSizeInBytes);
  
  @override
  String toString() => 'ImageTooLargeException: $message (${(sizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB / ${(maxSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB)';
}
