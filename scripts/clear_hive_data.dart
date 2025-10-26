import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Script to completely clear all Hive data
/// Run with: dart run scripts/clear_hive_data.dart
Future<void> main() async {
  print('🗑️ Starting comprehensive Hive data clearing...');
  
  try {
    // Try to close all open boxes
    await Hive.close();
    print('✅ Closed all Hive boxes');
  } catch (e) {
    print('⚠️ Error closing boxes (might already be closed): $e');
  }
  
  try {
    // Delete from disk
    await Hive.deleteFromDisk();
    print('✅ Deleted Hive data from disk using Hive.deleteFromDisk()');
  } catch (e) {
    print('⚠️ Error with Hive.deleteFromDisk(): $e');
  }
  
  // Manual deletion of Hive directories
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDocDir.path}/hive');
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
      print('✅ Manually deleted Hive directory');
    } else {
      print('ℹ️ Hive directory does not exist');
    }
  } catch (e) {
    print('⚠️ Error manually deleting Hive directory: $e');
  }
  
  // Try to delete common Hive file patterns
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final directory = Directory(appDocDir.path);
    
    await for (final file in directory.list(recursive: true)) {
      if (file.path.contains('.hive') || file.path.contains('.lock')) {
        try {
          if (await File(file.path).exists()) {
            await File(file.path).delete();
            print('🗑️ Deleted: ${file.path}');
          }
        } catch (e) {
          print('⚠️ Could not delete ${file.path}: $e');
        }
      }
    }
  } catch (e) {
    print('⚠️ Error scanning for Hive files: $e');
  }
  
  print('✅ Hive data clearing complete!');
}
