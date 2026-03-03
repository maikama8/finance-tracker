import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/receipt_processor.dart';
import '../../domain/value_objects/receipt_data.dart';
import '../../application/state/receipt_provider.dart';

/// Result returned from receipt capture screen
class ReceiptCaptureResult {
  final String imageId;
  final ReceiptData? receiptData;

  const ReceiptCaptureResult({
    required this.imageId,
    this.receiptData,
  });
}

/// Screen for capturing receipt photos with OCR
class ReceiptCaptureScreen extends ConsumerStatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  ConsumerState<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends ConsumerState<ReceiptCaptureScreen> {
  File? _imageFile;
  ReceiptData? _extractedData;
  bool _isProcessing = false;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.captureReceipt ?? 'Capture Receipt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview or Placeholder
            if (_imageFile != null)
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _isProcessing ? null : _retakePhoto,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n?.retake ?? 'Retake'),
                          ),
                          TextButton.icon(
                            onPressed: _isProcessing ? null : _processReceipt,
                            icon: const Icon(Icons.document_scanner),
                            label: Text(l10n?.extractData ?? 'Extract Data'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.noImageSelected ?? 'No image selected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Processing Indicator
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Processing receipt...'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isProcessing) const SizedBox(height: 16),

            // Extracted Data Display
            if (_extractedData != null && !_isProcessing)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.dataExtracted ?? 'Data Extracted',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_extractedData!.amount != null)
                        _buildDataRow(
                          l10n?.amount ?? 'Amount',
                          '${_extractedData!.currency?.symbol ?? ''} ${_extractedData!.amount}',
                        ),
                      if (_extractedData!.date != null)
                        _buildDataRow(
                          l10n?.date ?? 'Date',
                          _extractedData!.date.toString().split(' ')[0],
                        ),
                      if (_extractedData!.merchantName != null)
                        _buildDataRow(
                          l10n?.merchant ?? 'Merchant',
                          _extractedData!.merchantName!,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n?.confidence ?? 'Confidence'}: ${(_extractedData!.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_extractedData != null && !_isProcessing) const SizedBox(height: 16),

            // Camera and Gallery Buttons
            if (_imageFile == null) ...[
              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n?.takePhoto ?? 'Take Photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(l10n?.chooseFromGallery ?? 'Choose from Gallery'),
              ),
            ],

            // Confirm Button (shown when image is selected)
            if (_imageFile != null && !_isProcessing) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isUploading ? null : _confirmAndUpload,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n?.confirm ?? 'Confirm'),
              ),
            ],

            // Manual Entry Option
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton(
                  onPressed: _confirmWithoutOCR,
                  child: Text(
                    l10n?.skipOCR ?? 'Skip OCR and enter manually',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _errorMessage = null;
          _extractedData = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
      _extractedData = null;
      _errorMessage = null;
    });
  }

  Future<void> _processReceipt() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final receiptProcessor = ref.read(receiptProcessorProvider);
      final extractedData = await receiptProcessor.extractData(_imageFile!);

      setState(() {
        _extractedData = extractedData;
        _isProcessing = false;
      });

      if (extractedData == null) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)?.ocrFailed ??
              'OCR extraction failed. You can still attach the receipt and enter data manually.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing receipt: $e';
      });
    }
  }

  Future<void> _confirmAndUpload() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final receiptProcessor = ref.read(receiptProcessorProvider);
      final imageId = await receiptProcessor.storeReceiptImage(_imageFile!);

      if (mounted) {
        Navigator.pop(
          context,
          ReceiptCaptureResult(
            imageId: imageId,
            receiptData: _extractedData,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error uploading receipt: $e';
      });
    }
  }

  Future<void> _confirmWithoutOCR() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final receiptProcessor = ref.read(receiptProcessorProvider);
      final imageId = await receiptProcessor.storeReceiptImage(_imageFile!);

      if (mounted) {
        Navigator.pop(
          context,
          ReceiptCaptureResult(
            imageId: imageId,
            receiptData: null,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error uploading receipt: $e';
      });
    }
  }
}
