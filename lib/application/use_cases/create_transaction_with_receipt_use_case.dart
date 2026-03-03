import 'dart:io';
import 'package:decimal/decimal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/receipt_processor.dart';
import '../../domain/value_objects/currency.dart';
import 'process_receipt_use_case.dart';

/// Use case for creating a transaction with receipt photo
/// 
/// Demonstrates OCR fallback logic:
/// - If OCR succeeds: Pre-fill transaction fields with extracted data
/// - If OCR fails: Allow manual entry with photo attached
/// - Photo is attached to transaction regardless of OCR success
/// 
/// **Validates: Requirements 5.3, 5.4**
class CreateTransactionWithReceiptUseCase {
  final TransactionRepository _transactionRepository;
  final ReceiptProcessor _receiptProcessor;
  
  CreateTransactionWithReceiptUseCase(
    this._transactionRepository,
    this._receiptProcessor,
  );
  
  /// Create a transaction with receipt photo
  /// 
  /// If [receiptImage] is provided:
  /// 1. Process the receipt (store + OCR)
  /// 2. If OCR succeeds and [useOcrData] is true, use extracted data
  /// 3. Otherwise, use manually provided data
  /// 4. Attach photo to transaction
  /// 
  /// **Validates: Requirements 5.3, 5.4**
  Future<TransactionWithReceiptResult> execute({
    required String userId,
    required String categoryId,
    required TransactionType type,
    File? receiptImage,
    // Manual entry fields (required if no OCR or OCR fails)
    Decimal? manualAmount,
    Currency? manualCurrency,
    DateTime? manualDate,
    String? manualNotes,
    // Whether to use OCR data if available
    bool useOcrData = true,
  }) async {
    String? receiptImageId;
    bool ocrUsed = false;
    Decimal? finalAmount;
    Currency? finalCurrency;
    DateTime? finalDate;
    String? finalNotes = manualNotes;
    
    // Process receipt if provided
    if (receiptImage != null) {
      final processUseCase = ProcessReceiptUseCase(_receiptProcessor);
      final receiptResult = await processUseCase.execute(receiptImage);
      
      receiptImageId = receiptResult.imageId;
      
      // Use OCR data if available and requested
      if (useOcrData && receiptResult.hasExtractedData) {
        final extracted = receiptResult.extractedData!;
        finalAmount = extracted.amount ?? manualAmount;
        finalCurrency = extracted.currency ?? manualCurrency;
        finalDate = extracted.date ?? manualDate;
        
        // Add merchant name to notes if available
        if (extracted.merchantName != null) {
          finalNotes = extracted.merchantName! + 
            (manualNotes != null ? '\n$manualNotes' : '');
        }
        
        ocrUsed = true;
      } else {
        // OCR failed or not used, use manual data
        finalAmount = manualAmount;
        finalCurrency = manualCurrency;
        finalDate = manualDate;
      }
    } else {
      // No receipt, use manual data
      finalAmount = manualAmount;
      finalCurrency = manualCurrency;
      finalDate = manualDate;
    }
    
    // Validate required fields
    if (finalAmount == null) {
      throw ArgumentError('Amount is required (either from OCR or manual entry)');
    }
    if (finalCurrency == null) {
      throw ArgumentError('Currency is required (either from OCR or manual entry)');
    }
    if (finalDate == null) {
      throw ArgumentError('Date is required (either from OCR or manual entry)');
    }
    
    // Create transaction input
    final transactionInput = TransactionInput(
      amount: finalAmount,
      currencyCode: finalCurrency.code,
      type: type,
      categoryId: categoryId,
      date: finalDate,
      notes: finalNotes,
      receiptImageId: receiptImageId,
    );
    
    final createdTransaction = await _transactionRepository.create(userId, transactionInput);
    
    return TransactionWithReceiptResult(
      transaction: createdTransaction,
      receiptImageId: receiptImageId,
      ocrUsed: ocrUsed,
    );
  }
}

/// Result of creating a transaction with receipt
class TransactionWithReceiptResult {
  final Transaction transaction;
  final String? receiptImageId;
  final bool ocrUsed;
  
  const TransactionWithReceiptResult({
    required this.transaction,
    this.receiptImageId,
    required this.ocrUsed,
  });
  
  bool get hasReceipt => receiptImageId != null;
  
  @override
  String toString() {
    return 'TransactionWithReceiptResult(id: ${transaction.id}, hasReceipt: $hasReceipt, ocrUsed: $ocrUsed)';
  }
}
