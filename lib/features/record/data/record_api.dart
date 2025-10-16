// lib/features/voice/data/record_api.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import '../../../core/constants/endpoints.dart';
import '../../../core/services/http_client.dart';


abstract class IVoiceApi {
  Future<Map<String, dynamic>> upload({required File file, double? durationSec});
  Future<Map<String, dynamic>> uploadBytes({required Uint8List bytes, required String filename, double? durationSec});
  Future<Map<String, dynamic>> getFile(String fileId);
  Future<Map<String, dynamic>> createModel({required String voiceFileId, String? modelName});
  Future<Map<String, dynamic>> getModel(String modelId);
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
        contentType: MediaType('audio', 'wav'),
      ),
      if (durationSec != null) 'duration': double.parse(durationSec.toStringAsFixed(2)),
    });

    final res = await http.raw.post<Map<String, dynamic>>(
      Endpoints.voiceUpload,
      data: form,
    );
    return res.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    double? durationSec,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType('audio', 'wav'),
      ),
      if (durationSec != null) 'duration': double.parse(durationSec.toStringAsFixed(2)),
    });

    final res = await http.raw.post<Map<String, dynamic>>(
      Endpoints.voiceUpload,
      data: form,
    );
    return res.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getFile(String fileId) async {
    final res = await http.raw.get<Map<String, dynamic>>(Endpoints.voiceGet(fileId));
    return res.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> createModel({required String voiceFileId, String? modelName}) async {
    final form = FormData.fromMap({
      'voiceFileId': voiceFileId,
      if (modelName != null && modelName.isNotEmpty) 'modelName': modelName,
    });
    final res = await http.raw.post<Map<String, dynamic>>(
      Endpoints.modelCreate,
      data: form,
    );
    return res.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getModel(String modelId) async {
    final res = await http.raw.get<Map<String, dynamic>>(Endpoints.modelGet(modelId));
    return res.data ?? <String, dynamic>{};
  }

  // record_api.dart
  Future<List<dynamic>> getMyModels() async {
    final res = await http.raw.get<List<dynamic>>(Endpoints.modelMyModels);
    return res.data ?? const [];
  }
}
