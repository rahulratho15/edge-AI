import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelManager {
  // Qwen3.5-0.8B Q8_0 (Full Quality) — ~812 MB
  static const String modelUrl =
      'https://huggingface.co/lmstudio-community/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q8_0.gguf';
  static const String mmprojUrl =
      'https://huggingface.co/lmstudio-community/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-Qwen3.5-0.8B-BF16.gguf';

  static const String modelFilename = 'Qwen3.5-0.8B-Q8_0.gguf';
  static const String mmprojFilename = 'mmproj-Qwen3.5-0.8B-BF16.gguf';

  String? _modelsDir;

  Future<String> get modelsDir async {
    if (_modelsDir != null) return _modelsDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _modelsDir = '${appDir.path}/models';
    final dir = Directory(_modelsDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _modelsDir!;
  }

  Future<String> get modelPath async => '${await modelsDir}/$modelFilename';
  Future<String> get mmprojPath async => '${await modelsDir}/$mmprojFilename';

  Future<bool> isModelDownloaded() async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  Future<bool> isMmprojDownloaded() async {
    final path = await mmprojPath;
    return File(path).existsSync();
  }

  Future<bool> areAllModelsReady() async {
    return await isModelDownloaded() && await isMmprojDownloaded();
  }

  /// Downloads a file from [url] to [destPath] with progress callback.
  /// [onProgress] receives (bytesReceived, totalBytes). totalBytes may be -1.
  Future<void> downloadFile(
    String url,
    String destPath, {
    void Function(int bytesReceived, int totalBytes)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? -1;
      int bytesReceived = 0;

      final file = File(destPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        onProgress?.call(bytesReceived, totalBytes);
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Downloads the main GGUF model with progress.
  Future<void> downloadModel({
    void Function(int bytesReceived, int totalBytes)? onProgress,
  }) async {
    final path = await modelPath;
    if (!File(path).existsSync()) {
      await downloadFile(modelUrl, path, onProgress: onProgress);
    }
  }

  /// Downloads the multimodal projector (vision) with progress.
  Future<void> downloadMmproj({
    void Function(int bytesReceived, int totalBytes)? onProgress,
  }) async {
    final path = await mmprojPath;
    if (!File(path).existsSync()) {
      await downloadFile(mmprojUrl, path, onProgress: onProgress);
    }
  }

  /// Delete all downloaded models.
  Future<void> deleteModels() async {
    final dir = Directory(await modelsDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Get the size of a downloaded file in bytes.
  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Format bytes to human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
