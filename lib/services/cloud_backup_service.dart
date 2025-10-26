import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import 'settings_service.dart';

enum BackupStatus { pending, inProgress, completed, failed, restoring }

enum BackupType { automatic, manual, scheduled }

class BackupMetadata {
  final String id;
  final String userId;
  final String fileName;
  final String cloudPath;
  final DateTime createdAt;
  final int fileSize;
  final String checksum;
  final BackupType type;
  final BackupStatus status;
  final String? errorMessage;
  final Map<String, int> itemCounts; // transactions, categories, budgets count
  final String appVersion;

  BackupMetadata({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.cloudPath,
    required this.createdAt,
    required this.fileSize,
    required this.checksum,
    required this.type,
    required this.status,
    this.errorMessage,
    required this.itemCounts,
    required this.appVersion,
  });

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? '',
      cloudPath: map['cloudPath'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      fileSize: map['fileSize'] ?? 0,
      checksum: map['checksum'] ?? '',
      type: BackupType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => BackupType.manual,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => BackupStatus.pending,
      ),
      errorMessage: map['errorMessage'],
      itemCounts: Map<String, int>.from(map['itemCounts'] ?? {}),
      appVersion: map['appVersion'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'cloudPath': cloudPath,
      'createdAt': Timestamp.fromDate(createdAt),
      'fileSize': fileSize,
      'checksum': checksum,
      'type': type.toString(),
      'status': status.toString(),
      'errorMessage': errorMessage,
      'itemCounts': itemCounts,
      'appVersion': appVersion,
    };
  }

  BackupMetadata copyWith({BackupStatus? status, String? errorMessage}) {
    return BackupMetadata(
      id: id,
      userId: userId,
      fileName: fileName,
      cloudPath: cloudPath,
      createdAt: createdAt,
      fileSize: fileSize,
      checksum: checksum,
      type: type,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      itemCounts: itemCounts,
      appVersion: appVersion,
    );
  }
}

class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  // Collection references
  CollectionReference get _backupsCollection =>
      _firestore.collection('backup_metadata');

  /// Create a cloud backup with metadata tracking
  Future<BackupMetadata> createCloudBackup({
    BackupType type = BackupType.manual,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final backupId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName =
        'finance_backup_${user.uid}_${_fileNameDateFormat.format(DateTime.now())}.json';
    final cloudPath = 'backups/${user.uid}/$fileName';

    // Create initial metadata
    final metadata = BackupMetadata(
      id: backupId,
      userId: user.uid,
      fileName: fileName,
      cloudPath: cloudPath,
      createdAt: DateTime.now(),
      fileSize: 0,
      checksum: '',
      type: type,
      status: BackupStatus.inProgress,
      itemCounts: {},
      appVersion: '1.0.0', // Get from package info
    );

    try {
      // Save initial metadata
      await _backupsCollection.doc(backupId).set(metadata.toMap());

      // Get username from settings
      final settingsService = SettingsService();
      final userName = await settingsService.getUsername();

      // Export data
      final exportData = DatabaseService.instance.exportData(
        userId: user.uid,
        userName: userName,
      );

      // Calculate item counts
      final itemCounts = {
        'transactions': (exportData['transactions'] as List?)?.length ?? 0,
        'categories': (exportData['categories'] as List?)?.length ?? 0,
        'budgets': (exportData['budgets'] as List?)?.length ?? 0,
        'savingsGoals': (exportData['savingsGoals'] as List?)?.length ?? 0,
        'savingsContributions':
            (exportData['savingsContributions'] as List?)?.length ?? 0,
      };

      // Add metadata to export
      exportData['backupMetadata'] = {
        'id': backupId,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'type': type.toString(),
        'itemCounts': itemCounts,
      };

      // Convert to JSON
      final jsonData = jsonEncode(exportData);
      final bytes = utf8.encode(jsonData);

      // Calculate checksum
      final checksum = sha256.convert(bytes).toString();

      // Upload to Firebase Storage
      final uploadTask = _storage
          .ref(cloudPath)
          .putData(
            Uint8List.fromList(bytes),
            SettableMetadata(
              contentType: 'application/json',
              customMetadata: {
                'userId': user.uid,
                'backupId': backupId,
                'checksum': checksum,
                'itemCounts': jsonEncode(itemCounts),
              },
            ),
          );

      await uploadTask;

      // Update metadata with final info
      final finalMetadata = metadata
          .copyWith(status: BackupStatus.completed)
          .copyWith();
      final updatedMetadata = BackupMetadata(
        id: backupId,
        userId: user.uid,
        fileName: fileName,
        cloudPath: cloudPath,
        createdAt: metadata.createdAt,
        fileSize: bytes.length,
        checksum: checksum,
        type: type,
        status: BackupStatus.completed,
        itemCounts: itemCounts,
        appVersion: metadata.appVersion,
      );

      await _backupsCollection.doc(backupId).update(updatedMetadata.toMap());

      return updatedMetadata;
    } catch (e) {
      // Update metadata with error
      final errorMetadata = metadata.copyWith(
        status: BackupStatus.failed,
        errorMessage: e.toString(),
      );

      await _backupsCollection.doc(backupId).update(errorMetadata.toMap());

      throw Exception('Cloud backup failed: $e');
    }
  }

  /// Get all cloud backups for current user
  Future<List<BackupMetadata>> getCloudBackups() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _backupsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => BackupMetadata.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get cloud backups: $e');
    }
  }

  /// Restore from cloud backup
  Future<void> restoreFromCloudBackup(BackupMetadata metadata) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (metadata.userId != user.uid) {
      throw Exception('Backup does not belong to current user');
    }

    try {
      // Update status to restoring
      await _backupsCollection.doc(metadata.id).update({
        'status': BackupStatus.restoring.toString(),
      });

      // Download from Firebase Storage
      final ref = _storage.ref(metadata.cloudPath);
      final downloadData = await ref.getData();

      if (downloadData == null) {
        throw Exception('Failed to download backup file');
      }

      // Verify checksum
      final downloadedChecksum = sha256.convert(downloadData).toString();
      if (downloadedChecksum != metadata.checksum) {
        throw Exception('Backup file corrupted - checksum mismatch');
      }

      // Parse JSON
      final jsonString = utf8.decode(downloadData);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Validate backup format
      if (!_validateBackupData(data)) {
        throw Exception('Invalid backup format');
      }

      // Clear existing data (optional - ask user)
      // await DatabaseService.instance.clearAllData(userId: user.uid);

      // Import data
      await DatabaseService.instance.importData(data, user.uid);

      // Update status to completed
      await _backupsCollection.doc(metadata.id).update({
        'status': BackupStatus.completed.toString(),
        'errorMessage': null,
      });
    } catch (e) {
      // Update status to failed
      await _backupsCollection.doc(metadata.id).update({
        'status': BackupStatus.failed.toString(),
        'errorMessage': e.toString(),
      });

      throw Exception('Cloud restore failed: $e');
    }
  }

  /// Delete cloud backup
  Future<void> deleteCloudBackup(BackupMetadata metadata) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (metadata.userId != user.uid) {
      throw Exception('Backup does not belong to current user');
    }

    try {
      // Delete from Firebase Storage
      await _storage.ref(metadata.cloudPath).delete();

      // Delete metadata
      await _backupsCollection.doc(metadata.id).delete();
    } catch (e) {
      throw Exception('Failed to delete cloud backup: $e');
    }
  }

  /// Setup automatic backups
  Future<void> scheduleAutomaticBackup({
    required Duration interval,
    int maxBackups = 30,
  }) async {
    // This would typically be implemented with Cloud Functions
    // For now, we'll store the schedule preferences
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('backup_schedules').doc(user.uid).set({
      'userId': user.uid,
      'interval': interval.inHours,
      'maxBackups': maxBackups,
      'enabled': true,
      'lastBackup': null,
      'nextBackup': DateTime.now().add(interval).toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get backup schedule
  Future<Map<String, dynamic>?> getBackupSchedule() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('backup_schedules')
          .doc(user.uid)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Cleanup old backups
  Future<void> cleanupOldBackups({int keepCount = 10}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final backups = await getCloudBackups();

      if (backups.length <= keepCount) {
        return; // Nothing to cleanup
      }

      // Sort by creation date (newest first) and get old ones
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final oldBackups = backups.sublist(keepCount);

      // Delete old backups
      for (final backup in oldBackups) {
        await deleteCloudBackup(backup);
      }
    } catch (e) {
      throw Exception('Failed to cleanup old backups: $e');
    }
  }

  /// Download backup file locally
  Future<String> downloadBackupLocally(BackupMetadata metadata) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Download from Firebase Storage
      final ref = _storage.ref(metadata.cloudPath);
      final downloadData = await ref.getData();

      if (downloadData == null) {
        throw Exception('Failed to download backup file');
      }

      // Save to local directory
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/${metadata.fileName}';
      final file = File(localPath);
      await file.writeAsBytes(downloadData);

      return localPath;
    } catch (e) {
      throw Exception('Failed to download backup locally: $e');
    }
  }

  /// Validate backup data structure
  bool _validateBackupData(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('transactions') ||
        !data.containsKey('categories') ||
        !data.containsKey('budgets') ||
        !data.containsKey('savingsGoals') ||
        !data.containsKey('savingsContributions') ||
        !data.containsKey('userSettings') ||
        !data.containsKey('exportDate')) {
      return false;
    }

    // Validate data types
    if (data['transactions'] is! List ||
        data['categories'] is! List ||
        data['budgets'] is! List ||
        data['savingsGoals'] is! List ||
        data['savingsContributions'] is! List ||
        data['userSettings'] is! Map) {
      return false;
    }

    return true;
  }

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final backups = await getCloudBackups();
      final totalSize = backups.fold<int>(
        0,
        (sum, backup) => sum + backup.fileSize,
      );
      final completedBackups = backups
          .where((b) => b.status == BackupStatus.completed)
          .length;

      return {
        'totalBackups': backups.length,
        'completedBackups': completedBackups,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'oldestBackup': backups.isNotEmpty
            ? backups.last.createdAt.toIso8601String()
            : null,
        'newestBackup': backups.isNotEmpty
            ? backups.first.createdAt.toIso8601String()
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get storage stats: $e');
    }
  }

  /// Stream backup progress (for UI updates)
  Stream<BackupMetadata> watchBackupProgress(String backupId) {
    return _backupsCollection
        .doc(backupId)
        .snapshots()
        .map(
          (snapshot) =>
              BackupMetadata.fromMap(snapshot.data() as Map<String, dynamic>),
        );
  }

  /// Check if user has available cloud storage quota
  Future<bool> hasStorageQuota() async {
    try {
      final stats = await getStorageStats();
      final totalSizeMB = double.parse(stats['totalSizeMB']);

      // Example: 100MB limit for free users
      const quotaLimitMB = 100.0;

      return totalSizeMB < quotaLimitMB;
    } catch (e) {
      return true; // Assume available if can't check
    }
  }
}
