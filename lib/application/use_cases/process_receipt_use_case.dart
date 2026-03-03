import 'dart:io';
import '../../domain/services/receipt_processor.dart';
import '../../domain/value_objects/receipt_data.dart';

/// Use case for processing receipt images with OCR fallback
/// 
/// Demonstrates the complete receipt processing flow:
/// 1. Store the receipt image
/// 2. Attempt OCR extraction
/// 3. Return extracted data or null for manual entry
/// 4. Attach photo to transaction regardless of OCR success
/// 
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
class ProcessReceiptUseCase {
  final ReceiptProcessor _receiptProcessor;
  
  ProcessReceiptUseCase(this._receiptProcessor);
  
  /// Process a receipt image and return the result
  /// 
  /// Returns [ProcessReceiptResult] containing:
  /// - imageId: The stored image ID (always present)
  /// - extractedData: OCR extracted data (null if OCR failed)
  /// - requiresManualEntry: Whether user needs to manually enter data
  /// 
  /// **Validates: Requirements 5.4**
  Future<ProcessReceiptResult> execute(File receiptImage) async {
    // Step 1: Store the receipt image (always succeeds or throws)
    final imageId = await _receiptProcessor.storeReceiptImage(receiptImage);
    
    // Step 2: Attempt OCR extraction (may return null)
    final extractedData = await _receiptProcessor.extractData(receiptImage);
    
    // Step 3: Determine if manual entry is required
    final requiresManualEntry = extractedData == null || !extractedData.isValid;
    
    return ProcessReceiptResult(
      imageId: imageId,
      extractedData: extractedData,
      requiresManualEntry: requiresManualEntry,
    );
  }
}

/// Result of receipt processing
class ProcessReceiptResult {
  /// The stored image ID (always present)
  final String imageId;
  
  /// OCR extracted data (null if OCR failed or unavailable)
  final ReceiptData? extractedData;
  
  /// Whether user needs to manually enter transaction data
  final bool requiresManualEntry;
  
  const ProcessReceiptResult({
    required this.imageId,
    this.extractedData,
    required this.requiresManualEntry,
  });
  
  /// Whether OCR extraction was successful
  bool get hasExtractedData => extractedData != null && extractedData!.isValid;
  
  /// Whether the extracted data has high confidence
  bool get hasHighConfidence => extractedData?.isHighConfidence ?? false;
  
  @override
  String toString() {
    return 'ProcessReceiptResult(imageId: $imageId, hasData: $hasExtractedData, requiresManual: $requiresManualEntry)';
  }
}
