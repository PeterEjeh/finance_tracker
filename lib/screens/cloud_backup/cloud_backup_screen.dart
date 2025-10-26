import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:universal_html/html.dart' as html;

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final BackupService _backupService = BackupService();
  final AuthService _authService = AuthService();
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isLoading = false;

  Future<void> _backupToGoogleDrive() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (kIsWeb) {
        // On web, create JSON string directly
        final data = _backupService.createBackupFile(userId: userId);
        await _googleDriveService.uploadBackupFile(await data);
      } else {
        final path = await _backupService.createBackupFile(userId: userId);
        await _googleDriveService.uploadBackupFile(path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded to Google Drive')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Drive backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _backupData(bool share) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = _authService.currentUser?.uid;

      if (kIsWeb) {
        // On web, always download the file
        await _backupService.downloadBackupWeb(userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup downloaded to your device')),
          );
        }
      } else {
        final path = await _backupService.createBackupFile(userId: userId);

        if (share) {
          await Share.shareXFiles([
            XFile(path),
          ], subject: 'FinanceTracker Backup');
        } else {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final fileName = path.split('/').last;
            final newPath = '${downloadsDir.path}/$fileName';
            await File(path).copy(newPath);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backup saved to $newPath')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          if (kIsWeb) {
            // On web, pass the file bytes directly
            final fileData = result.files.single;
            await _backupService.restoreFromFile({
              'bytes': fileData.bytes,
              'name': fileData.name,
            }, userId: userId);
          } else {
            // On mobile/desktop, use file path
            final file = File(result.files.single.path!);
            await _backupService.restoreFromFile(file, userId: userId);
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Restore complete')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreFromGoogleDrive() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final files = await _googleDriveService.listBackupFiles();
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup files found on Google Drive.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select a backup file'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(file.name ?? 'No name'),
                  onTap: () {
                    Navigator.of(context).pop(file);
                  },
                );
              },
            ),
          ),
        ),
      );

      if (selectedFile != null) {
        final downloadedFile = await _googleDriveService.downloadFile(
          selectedFile.id!,
          selectedFile.name!,
        );
        if (downloadedFile != null) {
          final userId = _authService.currentUser?.uid;
          if (userId == null) {
            throw Exception('User not logged in');
          }
          await _backupService.restoreFromFile(downloadedFile, userId: userId);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Restore complete')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore from Google Drive failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    context,
                    icon: Icons.cloud_upload_outlined,
                    title: 'Backup',
                  ),
                  const SizedBox(height: 16),
                  _buildBackupCard(
                    context,
                    title: 'Backup to Google Drive',
                    subtitle: 'Recommended for easy restore across devices',
                    icon: Icons.cloud_upload,
                    iconColor: const Color(0xFF4285F4), // Google Drive blue
                    onTap: _backupToGoogleDrive,
                  ),
                  const SizedBox(height: 12),
                  _buildBackupCard(
                    context,
                    title: 'Save Backup to Device',
                    subtitle: 'Saves a backup file to your downloads folder',
                    icon: Icons.download,
                    iconColor: const Color(0xFF34A853), // Green for save
                    onTap: () => _backupData(false),
                  ),
                  const SizedBox(height: 12),
                  _buildBackupCard(
                    context,
                    title: 'Share Backup File',
                    subtitle: 'Share the backup file with other apps',
                    icon: Icons.share,
                    iconColor: const Color(0xFFEA4335), // Red for share
                    onTap: () => _backupData(true),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    icon: Icons.history, // Changed to history icon
                    title: 'Restore',
                  ),
                  const SizedBox(height: 16),
                  _buildBackupCard(
                    context,
                    title: 'Restore from Google Drive',
                    subtitle: 'Restore data from a Google Drive backup',
                    icon: Icons.cloud_download,
                    iconColor: const Color(0xFF4285F4), // Google Drive blue
                    onTap: _restoreFromGoogleDrive,
                  ),
                  const SizedBox(height: 12),
                  _buildBackupCard(
                    context,
                    title: 'Restore from Device',
                    subtitle: 'Restore data from a file on your device',
                    icon: Icons.restore,
                    iconColor: const Color(0xFF9C27B0), // Purple for restore
                    onTap: _restoreData,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero, // Remove default card margin
      elevation: 0, // Remove default card elevation
      color: Theme.of(
        context,
      ).colorScheme.surface, // Use surface color for card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ), // Slightly less rounded corners
        side: BorderSide(
          color: Theme.of(
            context,
          ).dividerColor.withOpacity(0.5), // Subtle border
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24, // Slightly larger avatar
                backgroundColor: iconColor.withOpacity(0.1),
                foregroundColor: iconColor,
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
