import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_finance_tracker/domain/services/receipt_processor.dart';
import 'package:personal_finance_tracker/infrastructure/services/receipt_processor_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ReceiptProcessor receiptProcessor;
  
  setUp(() {
    receiptProcessor = ReceiptProcessorImpl();
  });
  
  group('ReceiptProcessor - Image Validation', () {
    test('should reject non-existent file', () async {
      final nonExistentFile = File('/path/to/nonexistent/image.jpg');
      
      expect(
        () => receiptProcessor.storeReceiptImage(nonExistentFile),
        throwsA(isA<InvalidImageFormatException>()),
      );
    });
    
    test('should reject unsupported image format', () async {
      // Create a temporary file with unsupported extension
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test.bmp');
      await testFile.writeAsBytes([0, 0, 0, 0]); // Dummy data
      
      expect(
        () => receiptProcessor.storeReceiptImage(testFile),
        throwsA(isA<InvalidImageFormatException>()),
      );
      
      // Cleanup
      await testFile.delete();
    });
    
    test('should reject image larger than 10MB', () async {
      // Create a temporary file larger than 10MB
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/large_image.jpg');
      
      // Create 11MB of data
      final largeData = List<int>.filled(11 * 1024 * 1024, 0);
      await testFile.writeAsBytes(largeData);
      
      expect(
        () => receiptProcessor.storeReceiptImage(testFile),
        throwsA(isA<ImageTooLargeException>()),
      );
      
      // Cleanup
      await testFile.delete();
    });
  });
  
  group('ReceiptProcessor - Image Storage', () {
    test('should store and retrieve image successfully', () async {
      // Create a small valid JPEG file
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_receipt.jpg');
      
      // Minimal JPEG header
      final jpegData = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
        0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
        0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
      ];
      await testFile.writeAsBytes(jpegData);
      
      // Store the image
      final imageId = await receiptProcessor.storeReceiptImage(testFile);
      
      expect(imageId, isNotEmpty);
      expect(imageId.length, equals(36)); // UUID v4 length
      
      // Retrieve the image
      final retrievedImage = await receiptProcessor.getReceiptImage(imageId);
      
      expect(retrievedImage, isNotNull);
      expect(await retrievedImage!.exists(), isTrue);
      
      // Cleanup
      await testFile.delete();
      await receiptProcessor.deleteReceiptImage(imageId);
    });
    
    test('should return null for non-existent image ID', () async {
      final result = await receiptProcessor.getReceiptImage('non-existent-id');
      
      expect(result, isNull);
    });
    
    test('should delete image successfully', () async {
      // Create and store a test image
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_delete.jpg');
      
      final jpegData = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
        0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
        0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
      ];
      await testFile.writeAsBytes(jpegData);
      
      final imageId = await receiptProcessor.storeReceiptImage(testFile);
      
      // Verify it exists
      var retrievedImage = await receiptProcessor.getReceiptImage(imageId);
      expect(retrievedImage, isNotNull);
      
      // Delete it
      await receiptProcessor.deleteReceiptImage(imageId);
      
      // Verify it's gone
      retrievedImage = await receiptProcessor.getReceiptImage(imageId);
      expect(retrievedImage, isNull);
      
      // Cleanup
      await testFile.delete();
    });
  });
  
  group('ReceiptProcessor - OCR Extraction', () {
    test('should return null for empty or invalid image', () async {
      // Create a minimal invalid image
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/invalid.jpg');
      await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]); // Minimal JPEG
      
      final result = await receiptProcessor.extractData(testFile);
      
      // OCR should fail gracefully and return null
      expect(result, isNull);
      
      // Cleanup
      await testFile.delete();
    });
  });
  
  group('ReceiptProcessor - Edge Cases', () {
    test('should handle PNG format', () async {
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test.png');
      
      // Minimal PNG header
      final pngData = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
        0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
        0x44, 0xAE, 0x42, 0x60, 0x82
      ];
      await testFile.writeAsBytes(pngData);
      
      // Should not throw
      final imageId = await receiptProcessor.storeReceiptImage(testFile);
      expect(imageId, isNotEmpty);
      
      // Cleanup
      await testFile.delete();
      await receiptProcessor.deleteReceiptImage(imageId);
    });
    
    test('should handle JPEG with uppercase extension', () async {
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test.JPG');
      
      final jpegData = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
        0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
        0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
      ];
      await testFile.writeAsBytes(jpegData);
      
      // Should not throw (case-insensitive check)
      final imageId = await receiptProcessor.storeReceiptImage(testFile);
      expect(imageId, isNotEmpty);
      
      // Cleanup
      await testFile.delete();
      await receiptProcessor.deleteReceiptImage(imageId);
    });
    
    test('should not throw when deleting non-existent image', () async {
      // Should not throw
      await receiptProcessor.deleteReceiptImage('non-existent-id');
    });
  });
}
