import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class GoogleDriveService {
  final _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);

  Future<http.Client?> _getAuthenticatedClient() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    final authHeaders = await account.authHeaders;
    return _AuthenticatedClient(authHeaders);
  }

  Future<List<drive.File>> listBackupFiles() async {
    final client = await _getAuthenticatedClient();
    if (client == null) {
      return [];
    }
    final driveApi = drive.DriveApi(client);
    final result = await driveApi.files.list(
      q: "name contains 'finance_tracker_backup_'",
      spaces: 'drive',
    );
    return result.files ?? [];
  }

  Future<dynamic> downloadFile(String fileId, String fileName) async {
    if (kIsWeb) {
      // On web, return the media stream data instead of a File
      final client = await _getAuthenticatedClient();
      if (client == null) {
        return null;
      }
      final driveApi = drive.DriveApi(client);
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // Collect the stream data
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return {'bytes': bytes, 'name': fileName};
    } else {
      final client = await _getAuthenticatedClient();
      if (client == null) {
        return null;
      }
      final driveApi = drive.DriveApi(client);
      final media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      final fileSink = file.openWrite();
      await media.stream.pipe(fileSink);
      await fileSink.close();
      return file;
    }
  }

  Future<void> uploadBackupFile(dynamic pathOrData) async {
    final client = await _getAuthenticatedClient();
    if (client == null) {
      return;
    }
    final driveApi = drive.DriveApi(client);

    if (kIsWeb) {
      // On web, pathOrData is a JSON string
      final jsonString = pathOrData as String;
      final bytes = utf8.encode(jsonString);
      final request = drive.File();
      request.name =
          'finance_tracker_backup_${DateTime.now().toIso8601String()}.json';
      final media = drive.Media(Stream.value(bytes), bytes.length);
      await driveApi.files.create(request, uploadMedia: media);
    } else {
      final file = File(pathOrData as String);
      final request = drive.File();
      request.name = pathOrData.split('/').last;
      final media = drive.Media(file.openRead(), file.lengthSync());
      await driveApi.files.create(request, uploadMedia: media);
    }
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
