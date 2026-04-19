import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'llm_constants.dart';

/// Returns the directory into which the model is copied.
typedef AppDirProvider = Future<Directory> Function();

/// Copies the bundled Gemma 4 E2B INT4 model (`.litertlm`, ~1.3 GB) from
/// Flutter assets to a real filesystem path on first launch, so the native
/// LiteRT-LM runtime can `mmap` it.
///
/// Subsequent launches detect the file and skip the copy.
class GemmaModelLoader {
  GemmaModelLoader({AssetBundle? assetBundle, AppDirProvider? appDirProvider})
      : _assetBundle = assetBundle ?? rootBundle,
        _appDirProvider = appDirProvider ?? getApplicationDocumentsDirectory;

  static const _tag = 'GemmaModelLoader';

  final AssetBundle _assetBundle;
  final AppDirProvider _appDirProvider;
  String? _cachedPath;

  /// Ensures the model file is present on the local filesystem and returns
  /// its absolute path. Throws [LlmException.modelNotLoaded] (E009) on I/O
  /// error or missing asset.
  Future<String> ensureModelAvailable() async {
    if (_cachedPath != null) return _cachedPath!;

    try {
      final appDir = await _appDirProvider();
      final modelDir = Directory('${appDir.path}/${LlmConstants.modelsSubDir}');
      final target = File('${modelDir.path}/${LlmConstants.modelFileName}');

      if (await target.exists() && await target.length() > 0) {
        AppLogger.debug('Model already present at ${target.path}', _tag);
        _cachedPath = target.path;
        return target.path;
      }

      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      AppLogger.info('Copying bundled Gemma model to ${target.path}', _tag);
      final bytes = await _assetBundle.load(LlmConstants.modelAssetPath);
      await target.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      AppLogger.info(
        'Model copy complete (${await target.length()} bytes)',
        _tag,
      );
      _cachedPath = target.path;
      return target.path;
    } on LlmException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Failed to load Gemma model', _tag, e, s);
      throw LlmException.modelNotLoaded(originalError: e);
    }
  }

  /// Test-only helper to reset the in-memory cache.
  void resetCache() => _cachedPath = null;
}
