// The keys Settings writes for the shell into the Settings service, as
// docs/spec/shell-config.md in silica-desktop lists them.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/shell_config.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

(SilicaSettings, MemorySettingsBackend) store() {
  final backend = MemorySettingsBackend();
  return (SilicaSettings(backend: backend), backend);
}

void main() {
  group('typed writers', () {
    test('dock sizes are clamped and the magnified one follows the tile', () {
      final (s, b) = store();
      s.writeDockSizes(tile: 64, magnified: 90);
      expect(b.values, {'dock.tileSize': 64, 'dock.magnifiedSize': 90});
      s.writeDockSizes(tile: 500, magnified: 1);
      expect(b.values, {'dock.tileSize': 128, 'dock.magnifiedSize': 128});
      s.writeDockSizes(tile: 48, magnified: 1000);
      expect(b.values['dock.magnifiedSize'], 128);
    });

    test('dock launchAnimation and minimizeToApp', () {
      final (s, b) = store();
      s
        ..writeLaunchAnimation(LaunchAnimation.none)
        ..writeMinimizeToApp(true);
      expect(b.values, {
        'dock.launchAnimation': 'none',
        'dock.minimizeToApp': true,
      });
    });

    test('menu bar autohide, background, recentItems and clock', () {
      final (s, b) = store();
      s
        ..writeMenuBarAutohide(MenuBarAutohide.always)
        ..writeMenuBarBackground(false)
        ..writeRecentItems(15)
        ..writeClock(const ClockStyle(seconds: true));
      expect(b.values, {
        'menubar.autohide': 'always',
        'menubar.background': false,
        'menubar.recentItems': 15,
        'menubar.clock.hour24': true,
        'menubar.clock.seconds': true,
        'menubar.clock.weekday': true,
        'menubar.clock.date': 'auto',
      });
      // A count off the list is 10.
      s.writeRecentItems(7);
      expect(b.values['menubar.recentItems'], 10);
    });

    test('notification defaults and per-app keys', () {
      final (s, b) = store();
      s
        ..writeAppNotification('firefox', 'style', 'alerts')
        ..writeNotificationDefaults(
          previews: PreviewMode.unlocked,
          grouping: GroupingMode.byApp,
        )
        ..writeAppNotification('firefox', 'sound', false)
        ..writeAppNotification('org.x.Mail', 'previews', 'never');
      expect(b.values, {
        'notifications.apps.firefox.style': 'alerts',
        'notifications.previews': 'unlocked',
        'notifications.grouping': 'app',
        'notifications.apps.firefox.sound': false,
        'notifications.apps.org.x.Mail.previews': 'never',
      });
      // null resets the key: the app follows the defaults again.
      s.writeAppNotification('firefox', 'sound', null);
      expect(b.values, isNot(contains('notifications.apps.firefox.sound')));
      expect(b.writes.last, 'notifications.apps.firefox.sound');
    });

    test('the wallpaper choice is one of three keys; the fit stays', () {
      final (s, b) = store();
      s.writeWallpaperFit(WallpaperFit.fit);
      s.writeWallpaper({'image': '/a.png'});
      expect(s.wallpaperChoice(), {'image': '/a.png'});
      s.writeWallpaper({'color': '#102030'});
      expect(s.wallpaperChoice(), {'color': '#102030'});
      expect(b.values['wallpaper.image'], '');
      s.writeWallpaper({'wallpaper': 'positano-1'});
      expect(s.wallpaperChoice(), {'wallpaper': 'positano-1'});
      s.writeWallpaper(const {});
      expect(s.wallpaperChoice(), isEmpty);
      expect(b.values['wallpaper.fit'], 'fit');
    });

    test('password delay: -1 is never, 15 minutes by default', () {
      final (s, b) = store();
      expect(s.passwordDelay(), passwordDelayDefault);
      s.writePasswordDelay(null);
      expect(b.values['lockscreen.passwordDelay'], -1);
      expect(s.passwordDelay(), isNull);
      s.writePasswordDelay(60);
      expect(s.passwordDelay(), 60);
    });
  });

  group('keys written by the panes', () {
    testWidgets('dock', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock minimize effect', 'Scale effect');
      for (final key in ['dock magnify', 'dock autohide', 'dock indicators']) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(switchIn(key));
        await tester.pump();
      }
      expect(h.settings.values, {
        'dock.minimizeEffect': 'scale',
        'dock.magnify': true,
        'dock.autohide': true,
        'dock.indicators': false,
      });
    });

    testWidgets('menu bar', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.menuBar);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('menubar bluetooth')),
          matching: find.byType(AmalfiCheckbox),
        ),
      );
      await tester.pump();
      expect(h.settings.values, {'menubar.bluetooth': true});
    });
  });
}
