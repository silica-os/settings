import 'dart:io';

// Desktop & Dock, Menu Bar, Displays and Wallpaper: the shell's files and the tools.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Desktop & Dock', () {
    testWidgets('the switches write dock.json', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      for (final (key, option, value) in [
        ('dock magnify', 'magnify', true),
        ('dock autohide', 'autohide', true),
        ('dock indicators', 'indicators', false),
        ('dock recents', 'recents', true),
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(switchIn(key));
        await tester.pump();
        expect(h.config.flag('dock', option, fallback: !value), value);
      }
    });

    testWidgets('Minimize into the app icon writes minimizeToApp', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.desktopDock,
        height: 1400,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('dock minimize into icon')),
      );
      await tester.tap(switchIn('dock minimize into icon'));
      await tester.pump();
      expect(h.config.flag('dock', 'minimizeToApp', fallback: false), isTrue);
    });

    testWidgets('Animate opening apps writes launchAnimation', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await tester.ensureVisible(find.byKey(const ValueKey('dock animate')));
      expect(h.config.text('dock', 'launchAnimation', fallback: ''), '');
      await tester.tap(switchIn('dock animate'));
      await tester.pump();
      expect(h.config.text('dock', 'launchAnimation', fallback: ''), 'none');
      await tester.tap(switchIn('dock animate'));
      await tester.pump();
      expect(h.config.text('dock', 'launchAnimation', fallback: ''), 'bounce');
    });

    testWidgets('the Size slider writes tileSize while dragging', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      final slider = find.descendant(
        of: find.byKey(const ValueKey('dock size')),
        matching: find.byType(AmalfiSlider),
      );
      await tester.ensureVisible(slider);
      expect(h.config.number('dock', 'tileSize', fallback: -1), -1);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      final mid = h.config.number('dock', 'tileSize', fallback: -1);
      expect(mid, greaterThan(48));
      expect(mid, mid.roundToDouble());
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(h.config.number('dock', 'tileSize', fallback: -1), 128);
      // The magnified size never falls below the resting size.
      expect(
        h.config.number('dock', 'magnifiedSize', fallback: -1),
        greaterThanOrEqualTo(128),
      );
    });

    testWidgets('Magnification size needs Magnification', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      AmalfiSlider magnified() => tester.widget<AmalfiSlider>(
        find.descendant(
          of: find.byKey(const ValueKey('dock magnification size')),
          matching: find.byType(AmalfiSlider),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('dock magnification size')),
      );
      expect(magnified().enabled, isFalse);
      h.config.write('dock', 'magnify', true);
      await tester.pump(const Duration(seconds: 1));
      expect(magnified().enabled, isTrue);
      expect(magnified().min, 60);
      expect(magnified().max, 128);
    });

    testWidgets('an external dock.json change moves the Size slider', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      AmalfiSlider size() => tester.widget<AmalfiSlider>(
        find.descendant(
          of: find.byKey(const ValueKey('dock size')),
          matching: find.byType(AmalfiSlider),
        ),
      );
      expect(size().value, 60);
      // The shell writes tileSize when the Dock separator is dragged.
      h.config.write('dock', 'tileSize', 96);
      await tester.pump(const Duration(seconds: 1));
      expect(size().value, 96);
    });

    testWidgets('the title bar double click is written for the windows', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock double click', 'Minimise');
      expect(
        h.config.text('dock', 'titleBarDoubleClick', fallback: ''),
        'minimize',
      );
    });

    testWidgets('the minimize effect and the position', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock minimize effect', 'Scale effect');
      expect(h.config.text('dock', 'minimizeEffect', fallback: ''), 'scale');
      // The side Docks are not drawn yet: Left cannot be chosen.
      await choose(tester, 'dock position', 'Left');
      expect(h.config.text('dock', 'position', fallback: 'none'), 'none');
    });

    testWidgets('the default web browser goes through xdg-settings', (
      tester,
    ) async {
      final tools = FakeTools()
        ..browserList = const [
          AppEntry(id: 'firefox.desktop', name: 'Firefox'),
          AppEntry(id: 'chromium.desktop', name: 'Chromium'),
        ]
        ..browser = 'firefox.desktop';
      final h = await pumpSettings(
        tester,
        pane: PaneId.desktopDock,
        tools: tools,
        height: 1200,
      );
      await settle(tester);
      await choose(tester, 'default browser', 'Chromium');
      await settle(tester);
      expect(h.tools.calls, contains('browser chromium.desktop'));
    });

    testWidgets('a hot corner action is written to hotcorners.json', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.desktopDock,
        height: 1300,
      );
      await tapKey(tester, 'hot corners');
      await choose(tester, 'hot corner topLeft', 'Panorama');
      await choose(tester, 'hot corner bottomRight', 'Show desktop');
      expect(h.config.read('hotcorners'), {
        'topLeft': 'panorama',
        'bottomRight': 'desktop',
      });
      await choose(tester, 'hot corner topLeft', '—');
      expect(h.config.read('hotcorners'), {'bottomRight': 'desktop'});
    });

    testWidgets('the hot corners sheet opens and closes', (tester) async {
      await pumpSettings(tester, pane: PaneId.desktopDock, height: 1300);
      await tapKey(tester, 'hot corners');
      expect(find.byKey(const ValueKey('hot corners done')), findsOneWidget);
      await tapKey(tester, 'hot corners done');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('hot corners done')), findsNothing);
    });
  });

  testWidgets('Menu Bar: the status items write menubar.json', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    Finder check(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(AmalfiCheckbox),
    );
    await tester.tap(check('menubar bluetooth'));
    await tester.pump();
    expect(h.config.flag('menubar', 'bluetooth', fallback: false), isTrue);
    await choose(tester, 'menubar sound', 'Always show');
    expect(h.config.text('menubar', 'sound', fallback: ''), 'always');
    await tester.tap(check('menubar sound'));
    await tester.pump();
    expect(h.config.text('menubar', 'sound', fallback: ''), 'never');
    await tester.tap(switchIn('menubar battery percent'));
    await tester.pump();
    expect(h.config.flag('menubar', 'batteryPercent', fallback: false), isTrue);
  });

  testWidgets('Menu Bar: the recent items count is written', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    await choose(tester, 'menubar recent items', '20');
    expect(h.config.read('menubar')['recentItems'], 20);
    await choose(tester, 'menubar recent items', 'None');
    expect(h.config.read('menubar')['recentItems'], 0);
  });

  testWidgets(
    'Wallpaper: the fill mode is written and a new picture keeps it',
    (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.wallpaper);
      await choose(tester, 'wallpaper fit', 'Tile');
      expect(h.config.read('wallpaper')['fit'], 'tile');
      await tapKey(tester, 'wallpaper {color: #1f2a44}');
      expect(h.config.read('wallpaper'), {'fit': 'tile', 'color': '#1f2a44'});
      expect(find.textContaining('next login'), findsNothing);
    },
  );

  testWidgets(
    'Displays: without the compositor the machine\'s modes, read-only',
    (tester) async {
      final tools = FakeTools()
        ..outputs = const [
          DisplayOutput(
            connector: 'HDMI-A-1',
            modes: ['2560x1440', '1920x1080'],
          ),
        ];
      await pumpSettings(tester, pane: PaneId.displays, tools: tools);
      await settle(tester);
      expect(find.text('HDMI-A-1'), findsOneWidget);
      expect(find.text('2560 × 1440 (native)'), findsOneWidget);
      expect(find.text('1920 × 1080'), findsOneWidget);
      expect(find.textContaining('compositor didn’t report'), findsOneWidget);
    },
  );

  testWidgets('Wallpaper: a colour replaces the choice in wallpaper.json', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.wallpaper);
    await tapKey(tester, 'wallpaper {color: #1f2a44}');
    expect(h.config.read('wallpaper'), {'color': '#1f2a44'});
    await tapKey(tester, 'wallpaper {}');
    expect(h.config.read('wallpaper'), isEmpty);
  });

  testWidgets('Wallpaper: the Amalfi set with titles; the choice is its id', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('silica-wallpapers');
    addTearDown(() => root.deleteSync(recursive: true));
    final set = Directory('${root.path}/amalfi')..createSync();
    for (final id in ['positano-1', 'ravello']) {
      Directory('${set.path}/$id').createSync();
      File('${set.path}/$id/light.png').writeAsBytesSync([1]);
      File('${set.path}/$id/dark.png').writeAsBytesSync([2]);
    }
    File('${set.path}/wallpapers.json').writeAsStringSync(
      '{"wallpapers":['
      '{"id":"positano-1","title":"Positano 1","variants":{"light":{"file":"positano-1/light.png"},"dark":{"file":"positano-1/dark.png"}}},'
      '{"id":"ravello","title":"Ravello","variants":{"light":{"file":"ravello/light.png"},"dark":{"file":"ravello/dark.png"}}}]}',
    );
    final h = await pumpSettings(
      tester,
      pane: PaneId.wallpaper,
      extraEnv: {'SILICA_WALLPAPERS': root.path},
    );
    expect(find.text('Positano 1'), findsOneWidget);
    // Ravello is the default: the current wallpaper's name beside its preview.
    expect(find.text('Ravello'), findsWidgets);
    await tapKey(tester, 'wallpaper {wallpaper: positano-1}');
    expect(h.config.read('wallpaper'), {'wallpaper': 'positano-1'});
  });
}
