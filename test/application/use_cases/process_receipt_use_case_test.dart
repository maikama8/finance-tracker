import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/domain/services/receipt_processor.dart';
import 'package:personal_finance_tracker/domain/value_objects/receipt_data.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/application/use_cases/process_receipt_use_case.dart';

@GenerateMocks([ReceiptProcessor])
import 'process_receipt_use_case_test.mocks.dart';

void main() {
  late MockReceiptProcessor mockReceiptProcessor;
  late ProcessReceiptUseCase useCase;
  late File testFile;
  
  setUp(() {
    mockReceiptProcessor = MockReceiptProcessor();
    useCase = ProcessReceiptUseCase(mockReceiptProcessor);
    testFile = File('/tmp/test_receipt.jpg');
  });
  
  group('ProcessReceiptUseCase - Successful OCR', () {
    test('should process receipt with successful OCR extraction', () async {
      // Arrange
      const imageId = 'test-image-id';
      final receiptData = ReceiptData(
        amount: Decimal.parse('25.50'),
        date: DateTime(2024, 1, 15),
        merchantName: 'Test Store',
        currency: Currency.USD,
        confidence: 0.85,
      );
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => receiptData);
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert
      expect(result.imageId, equals(imageId));
      expect(result.extractedData, equals(receiptData));
      expect(result.requiresManualEntry, isFalse);
      expect(result.hasExtractedData, isTrue);
      expect(result.hasHighConfidence, isTrue);
      
      verify(mockReceiptProcessor.storeReceiptImage(testFile)).called(1);
      verify(mockReceiptProcessor.extractData(testFile)).called(1);
    });
    
    test('should indicate manual entry not required when OCR succeeds', () async {
      // Arrange
      const imageId = 'test-image-id';
      final receiptData = ReceiptData(
        amount: Decimal.parse('100.00'),
        date: DateTime(2024, 1, 15),
        merchantName: 'Coffee Shop',
        currency: Currency.USD,
        confidence: 0.9,
      );
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => receiptData);
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert
      expect(result.requiresManualEntry, isFalse);
      expect(result.hasExtractedData, isTrue);
    });
  });
  
  group('ProcessReceiptUseCase - OCR Failure', () {
    test('should handle OCR failure gracefully', () async {
      // Arrange
      const imageId = 'test-image-id';
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => null); // OCR failed
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert
      expect(result.imageId, equals(imageId));
      expect(result.extractedData, isNull);
      expect(result.requiresManualEntry, isTrue);
      expect(result.hasExtractedData, isFalse);
      expect(result.hasHighConfidence, isFalse);
      
      verify(mockReceiptProcessor.storeReceiptImage(testFile)).called(1);
      verify(mockReceiptProcessor.extractData(testFile)).called(1);
    });
    
    test('should require manual entry when OCR returns invalid data', () async {
      // Arrange
      const imageId = 'test-image-id';
      const receiptData = ReceiptData(
        amount: null, // Invalid - no amount
        date: null,
        merchantName: null,
        currency: null,
        confidence: 0.2,
      );
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => receiptData);
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert
      expect(result.imageId, equals(imageId));
      expect(result.extractedData, equals(receiptData));
      expect(result.requiresManualEntry, isTrue); // Invalid data
      expect(result.hasExtractedData, isFalse);
    });
    
    test('should attach photo regardless of OCR failure', () async {
      // Arrange
      const imageId = 'test-image-id';
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => null);
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert - Image is stored even when OCR fails
      expect(result.imageId, equals(imageId));
      expect(result.imageId, isNotEmpty);
      
      verify(mockReceiptProcessor.storeReceiptImage(testFile)).called(1);
    });
  });
  
  group('ProcessReceiptUseCase - Low Confidence OCR', () {
    test('should indicate low confidence when OCR confidence is below threshold', () async {
      // Arrange
      const imageId = 'test-image-id';
      final receiptData = ReceiptData(
        amount: Decimal.parse('50.00'),
        date: DateTime(2024, 1, 15),
        merchantName: 'Store',
        currency: Currency.USD,
        confidence: 0.5, // Low confidence
      );
      
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenAnswer((_) async => imageId);
      when(mockReceiptProcessor.extractData(testFile))
          .thenAnswer((_) async => receiptData);
      
      // Act
      final result = await useCase.execute(testFile);
      
      // Assert
      expect(result.hasExtractedData, isTrue);
      expect(result.hasHighConfidence, isFalse); // Below 0.7 threshold
    });
  });
  
  group('ProcessReceiptUseCase - Error Handling', () {
    test('should propagate storage errors', () async {
      // Arrange
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenThrow(InvalidImageFormatException('Invalid format'));
      
      // Act & Assert
      expect(
        () => useCase.execute(testFile),
        throwsA(isA<InvalidImageFormatException>()),
      );
      
      verify(mockReceiptProcessor.storeReceiptImage(testFile)).called(1);
      verifyNever(mockReceiptProcessor.extractData(any));
    });
    
    test('should propagate image size errors', () async {
      // Arrange
      when(mockReceiptProcessor.storeReceiptImage(testFile))
          .thenThrow(ImageTooLargeException('Too large', 11000000, 10000000));
      
      // Act & Assert
      expect(
        () => useCase.execute(testFile),
        throwsA(isA<ImageTooLargeException>()),
      );
    });
  });
}
