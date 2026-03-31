import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:personal_finance_tracker/domain/services/receipt_processor.dart';
import 'package:personal_finance_tracker/infrastructure/services/receipt_processor_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory testDirectory;
  late ReceiptProcessor receiptProcessor;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('receipt_processor_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      switch (methodCall.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationDocumentsDirectory':
          return testDirectory.path;
      }
      return testDirectory.path;
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);

    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() {
    receiptProcessor = ReceiptProcessorImpl();
  });

  Future<File> createValidJpegFile(Directory directory, String fileName) async {
    final image = img.Image(width: 2, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(img.encodeJpg(image));
    return file;
  }

  Future<File> createValidPngFile(Directory directory, String fileName) async {
    final image = img.Image(width: 2, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }
  
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

      await expectLater(
        receiptProcessor.storeReceiptImage(testFile),
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

      await expectLater(
        receiptProcessor.storeReceiptImage(testFile),
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
      final testFile = await createValidJpegFile(tempDir, 'test_receipt.jpg');
      
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
      final testFile = await createValidJpegFile(tempDir, 'test_delete.jpg');
      
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
      final testFile = await createValidPngFile(tempDir, 'test.png');
      
      // Should not throw
      final imageId = await receiptProcessor.storeReceiptImage(testFile);
      expect(imageId, isNotEmpty);
      
      // Cleanup
      await testFile.delete();
      await receiptProcessor.deleteReceiptImage(imageId);
    });
    
    test('should handle JPEG with uppercase extension', () async {
      final tempDir = await getTemporaryDirectory();
      final testFile = await createValidJpegFile(tempDir, 'test.JPG');
      
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
