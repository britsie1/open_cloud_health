import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/providers/theme_provider.dart';
import 'package:open_cloud_health/routing/app_router.dart';
import 'package:open_cloud_health/services/app_lifecycle_lock_manager.dart';
import 'package:open_cloud_health/theme/app_theme_mode.dart';
import 'package:open_cloud_health/theme/app_theme_preset.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:path/path.dart' as p;

import 'visual_font_loader.dart';
import 'visual_test_context.dart';

/// Metadata for a detected interactive UI element on the current screen.
class InteractiveElementInfo {
  final int index;
  final String widgetType;
  final String label;
  final Rect bounds;

  const InteractiveElementInfo({
    required this.index,
    required this.widgetType,
    required this.label,
    required this.bounds,
  });

  Offset get center => bounds.center;

  Map<String, dynamic> toJson() => {
        'index': index,
        'widgetType': widgetType,
        'label': label,
        'bounds': {
          'left': bounds.left.roundToDouble(),
          'top': bounds.top.roundToDouble(),
          'width': bounds.width.roundToDouble(),
          'height': bounds.height.roundToDouble(),
          'centerX': center.dx.roundToDouble(),
          'centerY': center.dy.roundToDouble(),
        },
      };
}

/// Record of a captured visual screen state during navigation.
class VisualCaptureRecord {
  final String name;
  final String flow;
  final String description;
  final String route;
  final String themeMode;
  final String themePreset;
  final Size deviceSize;
  final String screenshotPath;
  final String? annotatedScreenshotPath;
  final List<InteractiveElementInfo> interactiveElements;
  final List<String> visibleTexts;

  const VisualCaptureRecord({
    required this.name,
    required this.flow,
    required this.description,
    required this.route,
    required this.themeMode,
    required this.themePreset,
    required this.deviceSize,
    required this.screenshotPath,
    this.annotatedScreenshotPath,
    required this.interactiveElements,
    required this.visibleTexts,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'flow': flow,
        'description': description,
        'route': route,
        'themeMode': themeMode,
        'themePreset': themePreset,
        'deviceSize': {
          'width': deviceSize.width,
          'height': deviceSize.height,
        },
        'screenshotPath': screenshotPath,
        if (annotatedScreenshotPath != null)
          'annotatedScreenshotPath': annotatedScreenshotPath,
        'interactiveElements':
            interactiveElements.map((e) => e.toJson()).toList(),
        'visibleTexts': visibleTexts,
      };
}

/// Controller that mounts the Open Cloud Health application (with GoRouter,
/// Riverpod state, seeded Drift DB, real Material fonts, and themes) and allows
/// programmatic visual navigation, UI interaction, layout inspection, and
/// high-resolution PNG screenshot capture.
class VisualNavigator {
  final WidgetTester tester;
  final VisualTestContext ctx;
  final String outputDir;
  final double pixelRatio;

  final GlobalKey _repaintBoundaryKey = GlobalKey(debugLabel: 'VisualNavigatorBoundary');
  final ValueNotifier<List<InteractiveElementInfo>> _annotationsNotifier =
      ValueNotifier<List<InteractiveElementInfo>>(const []);

  late ProviderContainer _container;
  late GoRouter _router;
  Size _deviceSize;
  double _textScale;
  String _currentRoute = AppRoutes.auth;
  List<InteractiveElementInfo> _lastInspectedElements = const [];
  final List<VisualCaptureRecord> _captures = [];

  VisualNavigator({
    required this.tester,
    required this.ctx,
    String? outputDir,
    Size deviceSize = const Size(390, 844),
    this.pixelRatio = 2.0,
    double textScale = 1.0,
  })  : outputDir = outputDir ??
            p.join(Directory.current.path, 'build', 'visual_navigator'),
        _deviceSize = deviceSize,
        _textScale = textScale;

  List<VisualCaptureRecord> get captures => List.unmodifiable(_captures);
  ProviderContainer get container => _container;
  GoRouter get router => _router;
  String get screenshotsDir => p.join(outputDir, 'screenshots');

  /// Initializes fonts, viewport size, Riverpod container, and mounts the app
  /// at [initialLocation].
  Future<void> initializeApp({
    String initialLocation = AppRoutes.auth,
    Object? initialExtra,
    AppThemeMode themeMode = AppThemeMode.light,
    AppThemePreset preset = AppThemePresets.oceanBlue,
  }) async {
    debugDisableShadows = false;
    await VisualFontLoader.ensureFontsLoaded();

    Directory(screenshotsDir).createSync(recursive: true);

    await ctx.secureStorage.setThemeMode(themeMode);
    await ctx.secureStorage.setThemePreset(preset.id);

    _container = ProviderContainer(overrides: ctx.providerOverrides);
    _router = createAppRouter(
      initialLocation: initialLocation,
      initialExtra: initialExtra,
    );
    _currentRoute = initialLocation;

    _applyViewportSize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: _VisualHarnessApp(
          repaintBoundaryKey: _repaintBoundaryKey,
          router: _router,
          annotationsNotifier: _annotationsNotifier,
          deviceSize: _deviceSize,
          textScale: _textScale,
        ),
      ),
    );

    await VisualFontLoader.precacheAppAssets(tester);
    await settle();

    // Ensure theme state is synced in notifier
    await _container.read(themeNotifierProvider.notifier).setThemeMode(themeMode);
    await _container.read(themeNotifierProvider.notifier).setThemePreset(preset.id);
    await settle();
  }

  void _applyViewportSize() {
    tester.view.devicePixelRatio = pixelRatio;
    tester.view.physicalSize = _deviceSize * pixelRatio;
  }

  /// Pumps frames to allow async Riverpod providers, animations, and database
  /// streams to settle without hanging on infinite animations (like CircularProgressIndicator).
  Future<void> settle({int frames = 6, Duration step = const Duration(milliseconds: 80)}) async {
    await tester.pump();
    for (int i = 0; i < frames; i++) {
      await tester.pump(step);
    }
  }

  /// Navigates directly to [location] via GoRouter.
  Future<void> go(String location, {Object? extra}) async {
    _currentRoute = location;
    _router.go(location, extra: extra);
    await settle(frames: 8);
  }

  /// Pushes [location] onto the GoRouter navigation stack.
  Future<void> push(String location, {Object? extra}) async {
    _currentRoute = location;
    _router.push(location, extra: extra);
    await settle(frames: 8);
  }

  /// Pops the top route or modal dialog if possible.
  Future<void> pop() async {
    final navState = tester.stateList<NavigatorState>(find.byType(Navigator));
    if (navState.isNotEmpty) {
      await navState.last.maybePop();
      await settle(frames: 6);
    }
  }

  /// Taps a bottom navigation bar item by index (0: Home, 1: Medication, 2: History, 3: Profile).
  Future<void> tapBottomNav(int index) async {
    final navBarFinder = find.byType(BottomNavigationBar);
    if (navBarFinder.evaluate().isEmpty) {
      throw StateError('BottomNavigationBar is not currently visible on $_currentRoute');
    }
    final navBar = tester.widget<BottomNavigationBar>(navBarFinder.first);
    navBar.onTap?.call(index);
    const branchRoutes = [
      AppRoutes.home,
      AppRoutes.medicationTracker,
      AppRoutes.history,
      AppRoutes.profileDetail,
    ];
    if (index >= 0 && index < branchRoutes.length) {
      _currentRoute = '${branchRoutes[index]}/${ctx.primaryProfile.id}';
    }
    await settle(frames: 8);
  }

  /// Taps a [Tab] inside the currently visible onstage [TabBar] matching [tabLabel].
  Future<void> tapTab(String tabLabel) async {
    final visibleTabBars = find.byType(TabBar).hitTestable();
    if (visibleTabBars.evaluate().isEmpty) return;
    final tabFinder = find
        .descendant(
          of: visibleTabBars.last,
          matching: find.text(tabLabel),
        )
        .hitTestable();
    if (tabFinder.evaluate().isNotEmpty) {
      await tester.tap(tabFinder.last);
      await settle(frames: 8);
    }
  }

  /// Pushes a standalone modal/screen [widget] onto the active Navigator.
  Future<void> pushModalWidget(Widget widget, {String routeLabel = '/modal'}) async {
    _currentRoute = routeLabel;
    final scaffolds = find.byType(Scaffold).hitTestable().evaluate().toList();
    if (scaffolds.isNotEmpty) {
      Navigator.of(scaffolds.last).push(
        MaterialPageRoute<void>(builder: (_) => widget),
      );
      await settle(frames: 8);
    }
  }

  /// Taps the first visible widget containing [text].
  Future<bool> tapText(String text) async {
    final finder = find.text(text).hitTestable();
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.first);
      await settle(frames: 8);
      return true;
    }
    final containsFinder = find.textContaining(text).hitTestable();
    if (containsFinder.evaluate().isNotEmpty) {
      await tester.tap(containsFinder.first);
      await settle(frames: 8);
      return true;
    }
    return false;
  }

  /// Taps the first visible [Icon] matching [icon].
  Future<bool> tapIcon(IconData icon) async {
    final finder = find.byIcon(icon).hitTestable();
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.first);
      await settle(frames: 8);
      return true;
    }
    return false;
  }

  /// Taps an interactive element by its 1-based `#index` from [inspectElements].
  Future<bool> tapElementIndex(int index) async {
    final elements = _lastInspectedElements.isNotEmpty
        ? _lastInspectedElements
        : inspectElements();
    final match = elements.where((e) => e.index == index).firstOrNull;
    if (match == null) return false;
    await tester.tapAt(match.center);
    await settle(frames: 8);
    return true;
  }

  /// Scrolls the primary onstage vertical [Scrollable] down by [dy] logical pixels.
  Future<void> scrollDown({double dy = 380}) async {
    final scrollables = find.byType(Scrollable).hitTestable().evaluate().toList();
    for (final element in scrollables.reversed) {
      final widget = element.widget as Scrollable;
      if (widget.axisDirection == AxisDirection.down) {
        final renderObj = element.renderObject;
        if (renderObj is RenderBox && renderObj.hasSize && renderObj.size.height > 120) {
          await tester.drag(find.byElementPredicate((e) => e == element), Offset(0, -dy));
          await settle(frames: 6);
          return;
        }
      }
    }
  }

  /// Scrolls the primary onstage vertical [Scrollable] up by [dy] logical pixels.
  Future<void> scrollUp({double dy = 380}) async {
    final scrollables = find.byType(Scrollable).hitTestable().evaluate().toList();
    for (final element in scrollables.reversed) {
      final widget = element.widget as Scrollable;
      if (widget.axisDirection == AxisDirection.down) {
        final renderObj = element.renderObject;
        if (renderObj is RenderBox && renderObj.hasSize && renderObj.size.height > 120) {
          await tester.drag(find.byElementPredicate((e) => e == element), Offset(0, dy));
          await settle(frames: 6);
          return;
        }
      }
    }
  }

  /// Dynamically changes the active theme mode (Light/Dark) and/or color preset.
  Future<void> setTheme({
    AppThemeMode? mode,
    AppThemePreset? preset,
  }) async {
    final notifier = _container.read(themeNotifierProvider.notifier);
    if (mode != null) {
      await notifier.setThemeMode(mode);
    }
    if (preset != null) {
      await notifier.setThemePreset(preset.id);
    }
    await settle(frames: 6);
  }

  /// Toggles the privacy AppLockOverlay on or off.
  Future<void> setAppLocked(bool locked) async {
    _container.read(isAppLockedProvider.notifier).state = locked;
    await settle(frames: 6);
  }

  /// Changes the virtual device screen size and re-pumps the layout.
  Future<void> setDeviceSize(Size size, {double? textScale}) async {
    _deviceSize = size;
    if (textScale != null) _textScale = textScale;
    _applyViewportSize();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: _VisualHarnessApp(
          repaintBoundaryKey: _repaintBoundaryKey,
          router: _router,
          annotationsNotifier: _annotationsNotifier,
          deviceSize: _deviceSize,
          textScale: _textScale,
        ),
      ),
    );
    await settle(frames: 6);
  }

  /// Inspects all currently visible interactive widgets on screen and returns
  /// their 1-based `#index`, widget type, human-readable label, and bounding rect.
  List<InteractiveElementInfo> inspectElements() {
    final viewport = Offset.zero & _deviceSize;
    final results = <InteractiveElementInfo>[];
    final seenRects = <Rect>[];

    bool isInteractiveWidget(Widget w) {
      return w is ButtonStyleButton ||
          w is IconButton ||
          w is FloatingActionButton ||
          w is Tab ||
          w is Switch ||
          w is Checkbox ||
          w is Radio ||
          w is TextField ||
          w is Chip ||
          w is RawChip ||
          w is PopupMenuButton ||
          w is DropdownButton ||
          w is ListTile ||
          w is ExpansionTile ||
          (w is InkWell && w.onTap != null);
    }

    String extractLabel(Element el) {
      final w = el.widget;
      if (w is Tooltip && w.message != null && w.message!.isNotEmpty) {
        return w.message!;
      }
      if (w is IconButton && w.tooltip != null && w.tooltip!.isNotEmpty) {
        return w.tooltip!;
      }
      if (w is TextField && w.decoration?.labelText != null) {
        return 'Input: ${w.decoration!.labelText}';
      }
      final texts = <String>[];
      IconData? foundIcon;
      void visitChildren(Element child) {
        final cw = child.widget;
        if (cw is Text && cw.data != null && cw.data!.trim().isNotEmpty) {
          texts.add(cw.data!.trim());
        } else if (cw is Icon && cw.icon != null && foundIcon == null) {
          foundIcon = cw.icon;
        }
        child.visitChildren(visitChildren);
      }

      el.visitChildren(visitChildren);
      if (texts.isNotEmpty) {
        final joined = texts.join(' · ');
        return joined.length > 60 ? '${joined.substring(0, 57)}...' : joined;
      }
      if (foundIcon != null) {
        return 'Icon(0x${foundIcon!.codePoint.toRadixString(16)})';
      }
      return w.runtimeType.toString();
    }

    final onstageElements = find
        .byElementPredicate((el) => isInteractiveWidget(el.widget), skipOffstage: true)
        .hitTestable()
        .evaluate();

    for (final element in onstageElements) {
      final ro = element.renderObject;
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      final topLeft = ro.localToGlobal(Offset.zero);
      final rect = topLeft & ro.size;
      if (rect.width < 12 || rect.height < 12) continue;
      final clipped = rect.intersect(viewport);
      if (clipped.width < 10 || clipped.height < 10) continue;

      // Avoid duplicate nested wrappers (e.g. InkWell inside ElevatedButton)
      final isDuplicate = seenRects.any((r) =>
          (r.center - clipped.center).distance < 8.0 &&
          (r.width - clipped.width).abs() < 16.0 &&
          (r.height - clipped.height).abs() < 16.0);
      if (isDuplicate) continue;

      seenRects.add(clipped);
      results.add(
        InteractiveElementInfo(
          index: results.length + 1,
          widgetType: element.widget.runtimeType.toString(),
          label: extractLabel(element),
          bounds: clipped,
        ),
      );
    }

    _lastInspectedElements = results;
    return results;
  }

  /// Extracts all visible text strings on the current screen in top-to-bottom order.
  List<String> extractVisibleTexts() {
    final viewport = Offset.zero & _deviceSize;
    final items = <(double, double, String)>[];
    for (final element in find.byType(Text, skipOffstage: true).evaluate()) {
      final textWidget = element.widget as Text;
      final str = textWidget.data?.trim();
      if (str == null || str.isEmpty) continue;
      final ro = element.renderObject;
      if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
      final pos = ro.localToGlobal(Offset.zero);
      final rect = pos & ro.size;
      if (!viewport.overlaps(rect)) continue;
      items.add((pos.dy, pos.dx, str));
    }
    items.sort((a, b) {
      final dyDiff = (a.$1 - b.$1).abs();
      if (dyDiff > 6) return a.$1.compareTo(b.$1);
      return a.$2.compareTo(b.$2);
    });
    final unique = <String>[];
    for (final item in items) {
      if (!unique.contains(item.$3)) {
        unique.add(item.$3);
      }
    }
    return unique;
  }

  /// Captures the current screen to `build/visual_navigator/screenshots/<name>.png`
  /// and records its metadata and interactive elements.
  /// If [annotate] is true, also saves `<name>_annotated.png` with numbered
  /// bounding boxes (`#1`, `#2`, ...) drawn over interactive elements.
  Future<VisualCaptureRecord> capture(
    String name, {
    String flow = 'General',
    String description = '',
    bool annotate = false,
  }) async {
    await settle(frames: 3);

    final elements = inspectElements();
    final visibleTexts = extractVisibleTexts();
    final themeSettings = _container.read(themeSettingsProvider);

    final cleanPath = p.join(screenshotsDir, '$name.png');
    await _rasterizeBoundaryToFile(cleanPath);

    String? annotatedPath;
    if (annotate) {
      _annotationsNotifier.value = elements;
      await tester.pump();
      annotatedPath = p.join(screenshotsDir, '${name}_annotated.png');
      await _rasterizeBoundaryToFile(annotatedPath);
      _annotationsNotifier.value = const [];
      await tester.pump();
    }

    final record = VisualCaptureRecord(
      name: name,
      flow: flow,
      description: description.isNotEmpty ? description : name,
      route: _currentRoute,
      themeMode: themeSettings.themeMode.name,
      themePreset: themeSettings.presetId,
      deviceSize: _deviceSize,
      screenshotPath: cleanPath,
      annotatedScreenshotPath: annotatedPath,
      interactiveElements: elements,
      visibleTexts: visibleTexts,
    );
    _captures.add(record);
    return record;
  }

  Future<void> _rasterizeBoundaryToFile(String filePath) async {
    final boundaryFinder = find.byKey(_repaintBoundaryKey);
    expect(boundaryFinder, findsOneWidget);
    final boundaryElement = boundaryFinder.evaluate().single;
    final imageFuture = captureImage(boundaryElement);

    await tester.runAsync(() async {
      final ui.Image image = await imageFuture;
      try {
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(filePath);
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        }
      } finally {
        image.dispose();
      }
    });
  }

  /// Writes `manifest.json`, `VISUAL_MAP.md`, and an interactive `index.html`
  /// gallery to [outputDir].
  Future<void> writeVisualAtlas() async {
    Directory(outputDir).createSync(recursive: true);

    final manifestFile = File(p.join(outputDir, 'manifest.json'));
    final manifestData = {
      'generatedAt': DateTime.now().toIso8601String(),
      'totalCaptures': _captures.length,
      'screenshotsDir': screenshotsDir,
      'captures': _captures.map((c) => c.toJson()).toList(),
    };
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifestData),
    );

    final mdBuffer = StringBuffer()
      ..writeln('# Open Cloud Health — Visual Navigation Atlas')
      ..writeln()
      ..writeln('Total captured screens: **${_captures.length}**')
      ..writeln()
      ..writeln('| # | Screen Name | Flow | Route | Theme | Interactive Elements | Screenshot |')
      ..writeln('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |');

    for (int i = 0; i < _captures.length; i++) {
      final c = _captures[i];
      final relPng = 'screenshots/${c.name}.png';
      mdBuffer.writeln(
        '| ${i + 1} | **`${c.name}`** | ${c.flow} | `${c.route}` | `${c.themeMode}` / `${c.themePreset}` | ${c.interactiveElements.length} | `$relPng` |',
      );
    }

    File(p.join(outputDir, 'VISUAL_MAP.md')).writeAsStringSync(mdBuffer.toString());
    File(p.join(outputDir, 'index.html')).writeAsStringSync(_buildHtmlGallery());
  }

  String _buildHtmlGallery() {
    final cardsHtml = StringBuffer();
    for (final c in _captures) {
      final relImg = 'screenshots/${c.name}.png';
      final elementsList = c.interactiveElements
          .take(12)
          .map((e) =>
              '<li><code>#${e.index}</code> <strong>${_escapeHtml(e.label)}</strong> <span>(${e.widgetType} @ ${e.bounds.left.round()},${e.bounds.top.round()})</span></li>')
          .join('\n');
      cardsHtml.writeln('''
      <div class="screen-card" data-flow="${_escapeHtml(c.flow)}" data-mode="${_escapeHtml(c.themeMode)}">
        <div class="card-header">
          <div>
            <span class="badge flow-badge">${_escapeHtml(c.flow)}</span>
            <span class="badge mode-badge">${_escapeHtml(c.themeMode)} · ${_escapeHtml(c.themePreset)}</span>
          </div>
          <h3>${_escapeHtml(c.name)}</h3>
          <p class="desc">${_escapeHtml(c.description)}</p>
          <code class="route">${_escapeHtml(c.route)}</code>
        </div>
        <div class="img-wrap">
          <a href="$relImg" target="_blank">
            <img src="$relImg" alt="${_escapeHtml(c.name)}" loading="lazy" />
          </a>
        </div>
        <details class="elements-drawer">
          <summary>${c.interactiveElements.length} Interactive Elements · ${c.visibleTexts.length} Text Nodes</summary>
          <ul>$elementsList</ul>
        </details>
      </div>
      ''');
    }

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Open Cloud Health — Visual Navigator Atlas</title>
  <style>
    :root {
      --bg: #0f172a;
      --surface: #1e293b;
      --border: #334155;
      --text: #f8fafc;
      --muted: #94a3b8;
      --accent: #38bdf8;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 24px 32px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
    }
    header {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border);
    }
    h1 { margin: 0 0 6px 0; font-size: 24px; }
    .subtitle { margin: 0; color: var(--muted); font-size: 14px; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
      gap: 24px;
    }
    .screen-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    .card-header { padding: 16px; }
    .card-header h3 { margin: 8px 0 4px 0; font-size: 16px; }
    .desc { margin: 0 0 8px 0; color: var(--muted); font-size: 13px; }
    .route {
      display: inline-block;
      font-size: 12px;
      color: var(--accent);
      background: rgba(56, 189, 248, 0.1);
      padding: 2px 8px;
      border-radius: 6px;
    }
    .badge {
      display: inline-block;
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 999px;
      margin-right: 6px;
    }
    .flow-badge { background: #0284c7; color: #fff; }
    .mode-badge { background: #334155; color: #cbd5e1; }
    .img-wrap {
      background: #090d16;
      padding: 12px;
      display: flex;
      justify-content: center;
    }
    .img-wrap img {
      width: 100%;
      max-width: 280px;
      height: auto;
      border-radius: 12px;
      border: 1px solid #334155;
      box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    }
    .elements-drawer {
      padding: 12px 16px;
      border-top: 1px solid var(--border);
      font-size: 12px;
      color: var(--muted);
    }
    .elements-drawer summary { cursor: pointer; font-weight: 600; color: var(--text); }
    .elements-drawer ul { margin: 8px 0 0 0; padding-left: 16px; }
    .elements-drawer li { margin-bottom: 4px; }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>🩺 Open Cloud Health — Visual Navigator Atlas</h1>
      <p class="subtitle">Rendered with real Material typography, icons, seeded Drift SQLite records, and GoRouter navigation (${_captures.length} screens)</p>
    </div>
  </header>
  <div class="grid">
    $cardsHtml
  </div>
</body>
</html>''';
  }

  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  /// Cleans up the mounted widget tree and resets the test view dimensions.
  Future<void> dispose() async {
    debugDisableShadows = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

class _VisualHarnessApp extends ConsumerWidget {
  final GlobalKey repaintBoundaryKey;
  final GoRouter router;
  final ValueNotifier<List<InteractiveElementInfo>> annotationsNotifier;
  final Size deviceSize;
  final double textScale;

  const _VisualHarnessApp({
    required this.repaintBoundaryKey,
    required this.router,
    required this.annotationsNotifier,
    required this.deviceSize,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: MediaQuery(
        data: MediaQueryData(
          size: deviceSize,
          devicePixelRatio: 2.0,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 12),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              MaterialApp.router(
                routerConfig: router,
                debugShowCheckedModeBanner: false,
                title: 'Open Cloud Health',
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                builder: (context, child) {
                  return AppLockOverlay(
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              ),
              ValueListenableBuilder<List<InteractiveElementInfo>>(
                valueListenable: annotationsNotifier,
                builder: (context, annotations, _) {
                  if (annotations.isEmpty) return const SizedBox.shrink();
                  return IgnorePointer(
                    child: CustomPaint(
                      size: deviceSize,
                      painter: _AnnotationBoxPainter(annotations),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationBoxPainter extends CustomPainter {
  final List<InteractiveElementInfo> elements;

  _AnnotationBoxPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final fillPaint = Paint()
      ..color = const Color(0x22FF1744)
      ..style = PaintingStyle.fill;

    final tagBgPaint = Paint()
      ..color = const Color(0xEEFF1744)
      ..style = PaintingStyle.fill;

    for (final el in elements) {
      final rrect = RRect.fromRectAndRadius(el.bounds, const Radius.circular(4));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, boxPaint);

      final textSpan = TextSpan(
        text: '#${el.index}',
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final tagWidth = tp.width + 6;
      final tagHeight = tp.height + 3;
      final tagLeft = el.bounds.left.clamp(0.0, size.width - tagWidth);
      final tagTop = (el.bounds.top - tagHeight)
          .clamp(0.0, size.height - tagHeight);

      final tagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tagLeft, tagTop, tagWidth, tagHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(tagRect, tagBgPaint);
      tp.paint(canvas, Offset(tagLeft + 3, tagTop + 1.5));
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationBoxPainter oldDelegate) =>
      oldDelegate.elements != elements;
}
