import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/receipt_processor.dart';
import '../../domain/value_objects/receipt_data.dart';
import '../../domain/value_objects/currency.dart';

/// Implementation of ReceiptProcessor service
/// 
/// Stores receipt images in local storage with compression.
/// Uses Google ML Kit for on-device OCR extraction.
/// 
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**
class ReceiptProcessorImpl implements ReceiptProcessor {
  static const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png'];
  static const int compressionQuality = 85; // JPEG quality (0-100)
  static const int maxImageWidth = 1920; // Max width for compression
  
  final Uuid _uuid = const Uuid();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  /// Store a receipt image with validation and compression
  /// 
  /// **Validates: Requirements 5.1, 5.5**
  @override
  Future<String> storeReceiptImage(File image) async {
    // Validate file exists
    if (!await image.exists()) {
      throw InvalidImageFormatException('Image file does not exist');
    }
    
    // Validate file size
    final fileSize = await image.length();
    if (fileSize > maxSizeInBytes) {
      throw ImageTooLargeException(
        'Image size exceeds maximum allowed size',
        fileSize,
        maxSizeInBytes,
      );
    }
    
    // Validate file format
    final extension = image.path.split('.').last.toLowerCase();
    if (!supportedFormats.contains(extension)) {
      throw InvalidImageFormatException(
        'Unsupported image format: $extension. Supported formats: ${supportedFormats.join(", ")}',
      );
    }
    
    // Read and decode image
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) {
      throw InvalidImageFormatException('Failed to decode image');
    }
    
    // Compress image if needed
    img.Image processedImage = decodedImage;
    if (decodedImage.width > maxImageWidth) {
      processedImage = img.copyResize(
        decodedImage,
        width: maxImageWidth,
      );
    }
    
    // Encode as JPEG with compression
    final compressedBytes = img.encodeJpg(processedImage, quality: compressionQuality);
    
    // Generate unique ID and save
    final imageId = _uuid.v4();
    final directory = await _getReceiptsDirectory();
    final savedFile = File('${directory.path}/$imageId.jpg');
    await savedFile.writeAsBytes(compressedBytes);
    
    return imageId;
  }
  
  /// Extract data from receipt using Google ML Kit OCR
  /// 
  /// **Validates: Requirements 5.2, 5.3**
  @override
  Future<ReceiptData?> extractData(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return null;
      }
      
      // Extract data from recognized text
      final amount = _extractAmount(recognizedText.text);
      final date = _extractDate(recognizedText.text);
      final merchantName = _extractMerchantName(recognizedText.text);
      final currency = _extractCurrency(recognizedText.text);
      
      // Calculate confidence based on what we found
      double confidence = 0.0;
      if (amount != null) confidence += 0.4;
      if (date != null) confidence += 0.3;
      if (merchantName != null) confidence += 0.2;
      if (currency != null) confidence += 0.1;
      
      return ReceiptData(
        amount: amount,
        date: date,
        merchantName: merchantName,
        currency: currency,
        confidence: confidence,
      );
    } catch (e) {
      // OCR failed, return null to allow manual entry
      return null;
    }
  }
  
  /// Retrieve a stored receipt image
  @override
  Future<File?> getReceiptImage(String imageId) async {
    final directory = await _getReceiptsDirectory();
    final file = File('${directory.path}/$imageId.jpg');
    
    if (await file.exists()) {
      return file;
    }
    
    return null;
  }
  
  /// Delete a stored receipt image
  @override
  Future<void> deleteReceiptImage(String imageId) async {
    final directory = await _getReceiptsDirectory();
    final file = File('${directory.path}/$imageId.jpg');
    
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Get the receipts storage directory
  Future<Directory> _getReceiptsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDir.path}/receipts');
    
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    
    return receiptsDir;
  }
  
  /// Extract amount from receipt text
  /// 
  /// Looks for patterns like:
  /// - Total: $12.34
  /// - Amount: 12.34
  /// - 12.34 USD
  Decimal? _extractAmount(String text) {
    // Common patterns for amounts
    final patterns = [
      RegExp(r'total[:\s]+\$?(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'amount[:\s]+\$?(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})\s*(?:usd|eur|gbp|ngn)', caseSensitive: false),
      RegExp(r'\$(\d+[.,]\d{2})'),
      RegExp(r'(\d+[.,]\d{2})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          return Decimal.parse(amountStr);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }
  
  /// Extract date from receipt text
  /// 
  /// Looks for common date patterns
  DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'), // DD/MM/YYYY or MM/DD/YYYY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'), // YYYY-MM-DD
      RegExp(r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{4})', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern == patterns[0]) {
            // DD/MM/YYYY or MM/DD/YYYY - assume DD/MM/YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (pattern == patterns[1]) {
            // YYYY-MM-DD
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (pattern == patterns[2]) {
            // DD Month YYYY
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!.toLowerCase();
            final year = int.parse(match.group(3)!);
            final monthMap = {
              'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
              'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
              'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
            };
            final month = monthMap[monthStr.substring(0, 3)];
            if (month != null) {
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }
  
  /// Extract merchant name from receipt text
  /// 
  /// Typically the first line or lines before the items
  String? _extractMerchantName(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      return null;
    }
    
    // Take the first non-empty line as merchant name
    // Filter out lines that look like addresses or phone numbers
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      
      // Skip if it looks like an address (contains numbers and street keywords)
      if (RegExp(r'\d+.*(?:street|st|avenue|ave|road|rd|blvd)', caseSensitive: false).hasMatch(trimmed)) {
        continue;
      }
      
      // Skip if it looks like a phone number
      if (RegExp(r'^\+?\d[\d\s\-\(\)]{8,}$').hasMatch(trimmed)) {
        continue;
      }
      
      // Skip if it's too short
      if (trimmed.length < 3) {
        continue;
      }
      
      return trimmed;
    }
    
    return lines.first.trim();
  }
  
  /// Extract currency from receipt text
  Currency? _extractCurrency(String text) {
    final currencyPatterns = {
      Currency.USD: [r'\$', r'usd', r'dollar'],
      Currency.EUR: [r'€', r'eur', r'euro'],
      Currency.GBP: [r'£', r'gbp', r'pound'],
      Currency.NGN: [r'₦', r'ngn', r'naira'],
      Currency.JPY: [r'¥', r'jpy', r'yen'],
      Currency.INR: [r'₹', r'inr', r'rupee'],
    };
    
    for (final entry in currencyPatterns.entries) {
      for (final pattern in entry.value) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }
  
  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
