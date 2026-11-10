import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Loads real Material Fonts (`Roboto` family and `MaterialIcons`) from the
/// local Flutter SDK cache into the `flutter_test` engine so screenshots
/// render actual typography and vector icons instead of `Ahem` blocks.
class VisualFontLoader {
  static bool _loaded = false;

  /// Resolves the Flutter SDK root directory from `.dart_tool/package_config.json`
  /// or `FLUTTER_ROOT` environment variable.
  static Directory? _resolveFlutterRoot() {
    final envRoot = Platform.environment['FLUTTER_ROOT'];
    if (envRoot != null && envRoot.isNotEmpty) {
      final dir = Directory(envRoot);
      if (dir.existsSync()) return dir;
    }

    try {
      final pkgConfigFile = File(p.join(Directory.current.path, '.dart_tool', 'package_config.json'));
      if (pkgConfigFile.existsSync()) {
        final decoded = jsonDecode(pkgConfigFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = (decoded['packages'] as List<dynamic>?) ?? const [];
        for (final entry in packages) {
          if (entry is Map<String, dynamic> && entry['name'] == 'flutter') {
            final rootUriStr = entry['rootUri'] as String?;
            if (rootUriStr != null) {
              final flutterPkgDir = Directory.fromUri(Uri.parse(rootUriStr));
              // flutterPkgDir is <flutter_sdk>/packages/flutter
              final sdkRoot = flutterPkgDir.parent.parent;
              if (sdkRoot.existsSync()) return sdkRoot;
            }
          }
        }
      }
    } catch (_) {}

    final fallback = Directory(r'C:\src\flutter');
    if (fallback.existsSync()) return fallback;
    return null;
  }

  /// Loads `Roboto`, fallback system families (`FlutterTest`, `Ahem`, `sans-serif`),
  /// and `MaterialIcons` into the Flutter test engine.
  static Future<void> ensureFontsLoaded() async {
    if (_loaded) return;

    final flutterRoot = _resolveFlutterRoot();
    if (flutterRoot == null) {
      debugPrint('VisualFontLoader: Could not locate Flutter SDK root for font loading.');
      return;
    }

    final materialFontsDir = Directory(
      p.join(flutterRoot.path, 'bin', 'cache', 'artifacts', 'material_fonts'),
    );
    if (!materialFontsDir.existsSync()) {
      debugPrint('VisualFontLoader: material_fonts directory not found at ${materialFontsDir.path}');
      return;
    }

    final robotoFiles = <String>[
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-light.ttf',
      'roboto-italic.ttf',
      'roboto-bolditalic.ttf',
      'roboto-mediumitalic.ttf',
      'roboto-lightitalic.ttf',
      'roboto-black.ttf',
      'roboto-thin.ttf',
      'robotocondensed-regular.ttf',
      'robotocondensed-bold.ttf',
    ];

    final robotoBytesList = <ByteData>[];
    for (final fileName in robotoFiles) {
      final file = File(p.join(materialFontsDir.path, fileName));
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        robotoBytesList.add(ByteData.view(Uint8List.fromList(bytes).buffer));
      }
    }

    // Register Roboto under 'Roboto' as well as test/platform fallback font families
    // so even widgets with default TextStyle() (e.g. charts, custom painters) render real glyphs.
    const textFontFamilies = <String>[
      'Roboto',
      'FlutterTest',
      'Ahem',
      'sans-serif',
      'Segoe UI',
      '.SF Pro Text',
      '.SF Pro Display',
    ];

    for (final family in textFontFamilies) {
      final loader = FontLoader(family);
      for (final byteData in robotoBytesList) {
        loader.addFont(Future<ByteData>.value(byteData));
      }
      await loader.load();
    }

    // Load MaterialIcons font so all Icons.* render properly
    final materialIconsFile = File(p.join(materialFontsDir.path, 'materialicons-regular.otf'));
    if (materialIconsFile.existsSync()) {
      final bytes = materialIconsFile.readAsBytesSync();
      final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future<ByteData>.value(byteData));
      await iconLoader.load();
    }

    _loaded = true;
  }

  /// Precaches bundled PNG image assets so [Image.asset] widgets paint immediately
  /// without blank frames during screenshot capture.
  static Future<void> precacheAppAssets(WidgetTester tester) async {
    final element = tester.binding.rootElement;
    if (element == null) return;

    const assets = <String>[
      AppAssets.logo,
      AppAssets.malePlaceholder,
      AppAssets.femalePlaceholder,
      'assets/images/icon.png',
    ];

    await tester.runAsync(() async {
      for (final assetPath in assets) {
        try {
          final provider = AssetImage(assetPath);
          await precacheImage(provider, element);
        } catch (_) {}
      }
    });
  }
}
