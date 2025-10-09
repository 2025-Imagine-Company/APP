// lib/features/voice/data/voice_api.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/services//http_client.dart';

abstract class IVoiceApi {
  Future<Map<String, dynamic>> upload({required File file, double? durationSec});
}

class VoiceApi implements IVoiceApi {
  final HttpClient http;
  VoiceApi(this.http);

  @override
  Future<Map<String, dynamic>> upload({required File file, double? durationSec}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
      if (durationSec != null) 'duration': durationSec,
    });

    final res = await http.raw.post<Map<String, dynamic>>(
      Endpoints.voiceUpload,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data ?? {};
  }
}
