import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/stt/stt_constants.dart';
import 'package:nilam_ai/services/stt/whisper_model_loader.dart';

/// Fake AssetBundle that returns pre-seeded bytes for a given asset path.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, Uint8List> _assets;
  int loadCalls = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCalls += 1;
    final bytes = _assets[key];
    if (bytes == null) {
      throw FlutterError('Asset not found: $key');
    }
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw UnimplementedError();
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model_loader_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Directory> fakeAppDir() async => tempDir;

  group('WhisperModelLoader.ensureModelAvailable', () {
    test('copies bundled asset on first call and returns file path', () async {
      final payload = Uint8List.fromList(
        List<int>.generate(2048, (i) => i % 256),
      );
      final bundle = _FakeAssetBundle({
        SttConstants.modelAssetPath: payload,
      });
      final loader = WhisperModelLoader(
        assetBundle: bundle,
        appDirProvider: fakeAppDir,
      );

      final path = await loader.ensureModelAvailable();

      expect(path, endsWith(SttConstants.modelFileName));
      final file = File(path);
      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(payload.length));
      expect(bundle.loadCalls, equals(1));
    });

    test('skips copy on subsequent calls when model already cached', () async {
      final payload = Uint8List.fromList(List<int>.filled(1024, 7));
      final bundle = _FakeAssetBundle({
        SttConstants.modelAssetPath: payload,
      });
      final loader = WhisperModelLoader(
        assetBundle: bundle,
        appDirProvider: fakeAppDir,
      );

      final p1 = await loader.ensureModelAvailable();
      final p2 = await loader.ensureModelAvailable();

      expect(p1, equals(p2));
      expect(bundle.loadCalls, equals(1));
    });

    test('skips copy when file already on disk (no cache) but not in memory',
        () async {
      final payload = Uint8List.fromList(List<int>.filled(1024, 3));
      final bundle = _FakeAssetBundle({
        SttConstants.modelAssetPath: payload,
      });
      final loader = WhisperModelLoader(
        assetBundle: bundle,
        appDirProvider: fakeAppDir,
      );

      await loader.ensureModelAvailable();
      loader.resetCache();
      await loader.ensureModelAvailable();

      expect(bundle.loadCalls, equals(1)); // second call used on-disk file
    });

    test('throws SttException.modelNotLoaded when asset is missing', () async {
      final bundle = _FakeAssetBundle(const {});
      final loader = WhisperModelLoader(
        assetBundle: bundle,
        appDirProvider: fakeAppDir,
      );

      await expectLater(
        loader.ensureModelAvailable(),
        throwsA(
          isA<SttException>().having((e) => e.code, 'code', 'E006'),
        ),
      );
    });

    test('creates the models subdirectory if missing', () async {
      final payload = Uint8List.fromList(List<int>.filled(1024, 1));
      final bundle = _FakeAssetBundle({
        SttConstants.modelAssetPath: payload,
      });
      final loader = WhisperModelLoader(
        assetBundle: bundle,
        appDirProvider: fakeAppDir,
      );

      expect(
        await Directory('${tempDir.path}/${SttConstants.modelsSubDir}')
            .exists(),
        isFalse,
      );

      await loader.ensureModelAvailable();

      expect(
        await Directory('${tempDir.path}/${SttConstants.modelsSubDir}')
            .exists(),
        isTrue,
      );
    });
  });
}
