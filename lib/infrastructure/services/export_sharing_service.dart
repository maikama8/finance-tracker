import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

/// Service for sharing exported files
/// 
/// Provides options to share via email, messaging, or save to device
class ExportSharingService {
  /// Share a file via the system share dialog
  /// 
  /// This allows users to share via email, messaging apps, or save to device
  Future<void> shareFile(File file, {String? subject}) async {
    final fileName = path.basename(file.path);
    
    // Use share_plus to share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Financial Report - $fileName',
      text: 'Here is your financial report',
    );
  }

  /// Share a PDF report
  Future<void> sharePDF(File pdfFile) async {
    await shareFile(
      pdfFile,
      subject: 'Financial Report PDF',
    );
  }

  /// Share a CSV export
  Future<void> shareCSV(File csvFile) async {
    await shareFile(
      csvFile,
      subject: 'Financial Data Export CSV',
    );
  }

  /// Save file to device downloads folder (platform-specific)
  /// 
  /// Returns the path where the file was saved
  Future<String> saveToDevice(File file) async {
    // On mobile, we can use the share dialog with "Save to Files" option
    // On desktop, we could implement a file picker to choose save location
    
    // For now, we'll use the share dialog which includes save options
    await shareFile(file);
    
    // Return the original file path
    return file.path;
  }

  /// Get a user-friendly file name for exports
  String getExportFileName(String type, DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return 'finance_${type}_$dateStr';
  }
}
