// The keys of the shell's components in the system Settings service
// (`dev.frascella.Silica.Settings1`, silica-desktop `docs/spec/shell-config.md`): names, value
// sets, ranges and defaults, and the typed readers and writers Settings uses for them
// (`SilicaSettings` of silica_ui). `test/shell_config_test.dart` pins the keys written.

import 'dart:async';

import 'package:silica_ui/silica_ui.dart';

/// dock.json sizes, in points of the icon (the shell draws 48 at rest, `iconSize`).
abstract final class DockSizes {
  static const double tileMin = 16;
  static const double tileMax = 128;
  static const double tileDefault = 60;

  /// The magnified icon grows up to 128 pt (Amalfi Dock, design decision 2026-10-16),
  /// and never below the resting size.
  static const double magnifiedMax = 128;
  static const double magnifiedDefault = 64;

  /// Whole points, inside [tileMin, tileMax].
  static int tile(double value) => value.isFinite
      ? value.clamp(tileMin, tileMax).round()
      : tileDefault.round();

  /// Whole points, from the resting size to [magnifiedMax].
  static int magnified(double value, int tile) => value.isFinite
      ? value.clamp(tile.toDouble(), magnifiedMax).round()
      : tile;
}

/// Whether the Dock's icon bounces while an app opens (dock.json `launchAnimation`).
enum LaunchAnimation { bounce, none }

/// When the menu bar hides (menubar.json `autohide`).
enum MenuBarAutohide { never, fullscreen, always }

/// Counts offered for the recent items (menubar.json `recentItems`).
const List<int> recentItemChoices = [0, 5, 10, 15, 20, 30, 50];

/// When the clock shows the date (menubar.json `clock.date`).
enum ClockDate { auto, always, never }

/// The menu bar clock (`menubar.clock.*`). 24 hours by default.
class ClockStyle {
  const ClockStyle({
    this.hour24 = true,
    this.seconds = false,
    this.weekday = true,
    this.date = ClockDate.auto,
  });

  final bool hour24;
  final bool seconds;
  final bool weekday;
  final ClockDate date;

  /// The clock in the settings.
  factory ClockStyle.of(SilicaSettings s) => ClockStyle(
    hour24: s.getBool('menubar.clock.hour24', fallback: true),
    seconds: s.getBool('menubar.clock.seconds', fallback: false),
    weekday: s.getBool('menubar.clock.weekday', fallback: true),
    date: s.getEnum(
      'menubar.clock.date',
      ClockDate.values,
      fallback: ClockDate.auto,
    ),
  );

  ClockStyle copyWith({
    bool? hour24,
    bool? seconds,
    bool? weekday,
    ClockDate? date,
  }) => ClockStyle(
    hour24: hour24 ?? this.hour24,
    seconds: seconds ?? this.seconds,
    weekday: weekday ?? this.weekday,
    date: date ?? this.date,
  );
}

/// How a notification shows its text (notifications.json `previews`).
enum PreviewMode { always, unlocked, never }

/// An app's previews: the default for all notifications, or its own.
enum AppPreviewMode { byDefault, always, unlocked, never }

/// An app's grouping in the Center (notifications.json `apps.<key>.grouping`).
enum AppGrouping { auto, app, off }

/// How notifications stack in the Center (notifications.json `grouping`).
enum GroupingMode { automatic, byApp, off }

/// How the image fills the screen (wallpaper.json `fit`).
enum WallpaperFit { fill, fit, stretch, center, tile }

/// The delays after which the lock screen asks for the password (lockscreen.json
/// `passwordDelay`, in seconds; null: never).
const List<int?> passwordDelayChoices = [0, 5, 60, 300, 900, 3600, null];

/// The default when lockscreen.json says nothing: the reference machine's 15 minutes.
const int passwordDelayDefault = 900;

/// The screen savers the shell draws (screensaver.json `saver`), in the order of the sheet.
const List<String> screenSaverChoices = ['drift', 'clock', 'colors'];

/// Minutes without input before the screen saver starts (screensaver.json `minutes`; 0: never).
const List<int> screenSaverMinutes = [1, 2, 5, 10, 20, 30, 60, 0];

/// Typed readers and writers of the shell's keys.
extension ShellSettings on SilicaSettings {
  /// The seconds before the password is asked for (null: never; 15 minutes by default).
  int? passwordDelay() {
    final v = getInt(
      'lockscreen.passwordDelay',
      fallback: passwordDelayDefault,
    );
    return v < 0 ? null : v;
  }

  /// `null` is never.
  void writePasswordDelay(int? seconds) =>
      unawaited(set('lockscreen.passwordDelay', seconds ?? -1));

  /// The saver chosen, and the minutes before it starts (0: never).
  String screenSaver() {
    final v = getText('screensaver.saver', fallback: screenSaverChoices.first);
    return screenSaverChoices.contains(v) ? v : screenSaverChoices.first;
  }

  int screenSaverAfter() {
    final v = getInt('screensaver.minutes', fallback: 0);
    return v > 0 ? v : 0;
  }

  void writeScreenSaver(String id) => unawaited(set('screensaver.saver', id));

  void writeScreenSaverMinutes(int minutes) =>
      unawaited(set('screensaver.minutes', minutes));

  void writeDockSizes({required double tile, required double magnified}) {
    final t = DockSizes.tile(tile);
    unawaited(
      setMany({
        'dock.tileSize': t,
        'dock.magnifiedSize': DockSizes.magnified(magnified, t),
      }),
    );
  }

  void writeLaunchAnimation(LaunchAnimation value) =>
      unawaited(set('dock.launchAnimation', value.name));

  void writeMinimizeToApp(bool value) =>
      unawaited(set('dock.minimizeToApp', value));

  void writeMenuBarAutohide(MenuBarAutohide value) =>
      unawaited(set('menubar.autohide', value.name));

  void writeMenuBarBackground(bool value) =>
      unawaited(set('menubar.background', value));

  void writeRecentItems(int count) => unawaited(
    set('menubar.recentItems', recentItemChoices.contains(count) ? count : 10),
  );

  void writeClock(ClockStyle style) => unawaited(
    setMany({
      'menubar.clock.hour24': style.hour24,
      'menubar.clock.seconds': style.seconds,
      'menubar.clock.weekday': style.weekday,
      'menubar.clock.date': style.date.name,
    }),
  );

  void writeNotificationDefaults({
    PreviewMode? previews,
    GroupingMode? grouping,
  }) {
    if (previews != null) {
      unawaited(set('notifications.previews', previews.name));
    }
    if (grouping != null) {
      unawaited(
        set('notifications.grouping', switch (grouping) {
          GroupingMode.automatic => 'auto',
          GroupingMode.byApp => 'app',
          GroupingMode.off => 'off',
        }),
      );
    }
  }

  /// One field of one app (`notifications.apps.<app>.<key>`). A null [value] resets the key
  /// (the app then follows the defaults).
  void writeAppNotification(String app, String key, Object? value) {
    final name = 'notifications.apps.$app.$key';
    unawaited(value == null ? reset(name) : set(name, value));
  }

  /// The choice, as the map of the picker's options (`image`, `color` or `wallpaper`: an id of
  /// the Amalfi set); empty when nothing is chosen.
  Map<String, Object?> wallpaperChoice() => {
    for (final (json, key) in _wallpaperKeys)
      if (getText(key, fallback: '') case final v when v.isNotEmpty) json: v,
  };

  /// Chooses a wallpaper: [choice] has one of `image`, `color`, `wallpaper` (or none: the
  /// default); the others are cleared, so the shell never sees two at once.
  void writeWallpaper(Map<String, Object?> choice) => unawaited(
    setMany({
      for (final (json, key) in _wallpaperKeys)
        key: switch (choice[json]) {
          final String v => v,
          _ => '',
        },
    }),
  );

  void writeWallpaperFit(WallpaperFit value) =>
      unawaited(set('wallpaper.fit', value.name));
}

const List<(String, String)> _wallpaperKeys = [
  ('image', 'wallpaper.image'),
  ('color', 'wallpaper.color'),
  ('wallpaper', 'wallpaper.id'),
];
