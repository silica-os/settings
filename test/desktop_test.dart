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
    testWidgets('the switches set the dock keys', (tester) async {
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
        expect(h.settings.values['dock.$option'], value);
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
      expect(h.settings.values['dock.minimizeToApp'], isTrue);
    });

    testWidgets('Animate opening apps writes launchAnimation', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await tester.ensureVisible(find.byKey(const ValueKey('dock animate')));
      expect(h.settings.values['dock.launchAnimation'], isNull);
      await tester.tap(switchIn('dock animate'));
      await tester.pump();
      expect(h.settings.values['dock.launchAnimation'], 'none');
      await tester.tap(switchIn('dock animate'));
      await tester.pump();
      expect(h.settings.values['dock.launchAnimation'], 'bounce');
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
      expect(h.settings.values['dock.tileSize'], isNull);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      final mid = (h.settings.values['dock.tileSize']! as num).toDouble();
      expect(mid, greaterThan(48));
      expect(mid, mid.roundToDouble());
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(h.settings.values['dock.tileSize'], 128);
      // The magnified size never falls below the resting size.
      expect(
        h.settings.values['dock.magnifiedSize'],
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
      h.settings.emit('dock.magnify', true);
      await tester.pump(const Duration(seconds: 1));
      expect(magnified().enabled, isTrue);
      expect(magnified().min, 60);
      expect(magnified().max, 128);
    });

    testWidgets('an external change of dock.tileSize moves the Size slider', (
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
      // The shell sets tileSize when the Dock separator is dragged.
      h.settings.emit('dock.tileSize', 96);
      await tester.pump();
      expect(size().value, 96);
    });

    testWidgets('the title bar double click is written for the windows', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock double click', 'Minimise');
      // The Settings service's key, which Ossido and silica_ui follow (#240).
      expect(h.settings.values['dock.titleBarDoubleClick'], 'minimize');
    });

    testWidgets('the minimize effect and the position', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock minimize effect', 'Scale effect');
      expect(h.settings.values['dock.minimizeEffect'], 'scale');
      // The side Docks are not drawn yet: Left cannot be chosen.
      await choose(tester, 'dock position', 'Left');
      expect(h.settings.values['dock.position'], isNull);
    });

    testWidgets('a hot corner action sets hotcorners.* (#240)', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.desktopDock,
        height: 1300,
      );
      await tapKey(tester, 'hot corners');
      await choose(tester, 'hot corner topLeft', 'Panorama');
      await choose(tester, 'hot corner bottomRight', 'Show desktop');
      expect(h.settings.values, {
        'hotcorners.topLeft': 'panorama',
        'hotcorners.bottomRight': 'desktop',
      });
      await choose(tester, 'hot corner topLeft', '—');
      expect(h.settings.values['hotcorners.topLeft'], 'none');
      expect(h.settings.values['hotcorners.bottomRight'], 'desktop');
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

  testWidgets('Menu Bar: the status items set the menubar keys', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    Finder check(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(AmalfiCheckbox),
    );
    await tester.tap(check('menubar bluetooth'));
    await tester.pump();
    expect(h.settings.values['menubar.bluetooth'], isTrue);
    await choose(tester, 'menubar sound', 'Always show');
    expect(h.settings.values['menubar.sound'], 'always');
    await tester.tap(check('menubar sound'));
    await tester.pump();
    expect(h.settings.values['menubar.sound'], 'never');
    await tester.tap(switchIn('menubar battery percent'));
    await tester.pump();
    expect(h.settings.values['menubar.batteryPercent'], isTrue);
  });

  testWidgets('Menu Bar: auto-hide and the background are written', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    await choose(tester, 'menubar autohide', 'Always');
    expect(h.settings.values['menubar.autohide'], 'always');
    await choose(tester, 'menubar autohide', 'Never');
    expect(h.settings.values['menubar.autohide'], 'never');
    await tester.tap(switchIn('menubar background'));
    await tester.pump();
    expect(h.settings.values['menubar.background'], isTrue);
  });

  testWidgets('Wallpaper: the screen saver sheet sets the screensaver keys', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.wallpaper, height: 1000);
    expect(h.settings.values['screensaver.saver'], isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('screen saver button')),
    );
    await tester.tap(find.byKey(const ValueKey('screen saver button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clock'));
    await tester.pump();
    expect(h.settings.values['screensaver.saver'], 'clock');
    await choose(tester, 'screen saver after', '10 minutes');
    expect(h.settings.values['screensaver.minutes'], 10);
    await choose(tester, 'screen saver after', 'Never');
    expect(h.settings.values['screensaver.minutes'], 0);
  });

  testWidgets('Menu Bar: the recent items count is written', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    await choose(tester, 'menubar recent items', '20');
    expect(h.settings.values['menubar.recentItems'], 20);
    await choose(tester, 'menubar recent items', 'None');
    expect(h.settings.values['menubar.recentItems'], 0);
  });

  testWidgets(
    'Wallpaper: the fill mode is written and a new picture keeps it',
    (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.wallpaper);
      await choose(tester, 'wallpaper fit', 'Tile');
      expect(h.settings.values['wallpaper.fit'], 'tile');
      await tapKey(tester, 'wallpaper {color: #1f2a44}');
      expect(h.settings.values['wallpaper.fit'], 'tile');
      expect(h.settings.values['wallpaper.color'], '#1f2a44');
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

  testWidgets('Wallpaper: a colour replaces the choice', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.wallpaper);
    await tapKey(tester, 'wallpaper {color: #1f2a44}');
    expect(h.settings.values['wallpaper.color'], '#1f2a44');
    await tapKey(tester, 'wallpaper {}');
    expect(h.settings.values['wallpaper.color'], '');
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
    expect(h.settings.values['wallpaper.id'], 'positano-1');
  });
}
