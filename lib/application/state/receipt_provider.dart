import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/receipt_processor.dart';
import '../../infrastructure/services/receipt_processor_impl.dart';

/// Provider for ReceiptProcessor
final receiptProcessorProvider = Provider<ReceiptProcessor>((ref) {
  return ReceiptProcessorImpl();
});
