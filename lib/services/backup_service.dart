import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'package:universal_html/html.dart' as html;

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  Future<String> createBackupFile({String? userId}) async {
    final data = DatabaseService.instance.exportData(userId: userId);
    final fileName =
        'finance_tracker_backup_${_fileNameDateFormat.format(DateTime.now())}.json';

    if (kIsWeb) {
      // On web, we don't create a file on disk, just return the data as a string
      // The actual download will be handled by the calling method
      return jsonEncode(data);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(data));
      return file.path;
    }
  }

  Future<void> shareBackup({String? userId}) async {
    if (kIsWeb) {
      // On web, download the file instead of sharing
      await downloadBackupWeb(userId: userId);
    } else {
      final path = await createBackupFile(userId: userId);
      await Share.shareXFiles([XFile(path)], subject: 'FinanceTracker Backup');
    }
  }

  Future<void> downloadBackupWeb({String? userId}) async {
    final data = DatabaseService.instance.exportData(userId: userId);
    final jsonString = jsonEncode(data);
    final fileName =
        'finance_tracker_backup_${_fileNameDateFormat.format(DateTime.now())}.json';

    // Create a blob and download it
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> restoreFromFile(dynamic file, {required String userId}) async {
    try {
      String contents;
      if (kIsWeb) {
        // On web, file is from file_picker and has different structure
        if (file is Map && file.containsKey('bytes')) {
          contents = String.fromCharCodes(file['bytes']);
        } else {
          throw Exception('Invalid file format for web');
        }
      } else {
        // On mobile/desktop, file is a File object
        contents = await (file as File).readAsString();
      }
      final Map<String, dynamic> data = jsonDecode(contents);
      await DatabaseService.instance.importData(data, userId);
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }
}
