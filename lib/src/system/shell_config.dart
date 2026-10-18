// The keys the shell reads from Silica's configuration files, in one place: names, value
// sets, ranges, defaults and the JSON Settings writes for them. The contract is
// `docs/spec/shell-config.md`; `test/shell_config_test.dart` pins the exact JSON.
//
// The keys marked "not wired" are written by these helpers as soon as the shell reads them
// and the matching control is enabled (AGENTS.md › Never fake): until then the controls stay
// disabled and Settings writes nothing for them. Wired today: the Dock's `launchAnimation`
// and `minimizeToApp`, the menu bar's `clock`, `recentItems`, `autohide` and `background`,
// the notification previews, grouping and `showInCenter`, the wallpaper `fit`.

import 'config.dart';

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

/// The menu bar clock (menubar.json `clock`). `hour24` absent is 24 hours.
class ClockStyle {
  const ClockStyle({
    this.hour24,
    this.seconds = false,
    this.weekday = true,
    this.date = ClockDate.auto,
  });

  final bool? hour24;
  final bool seconds;
  final bool weekday;
  final ClockDate date;

  /// The clock in menubar.json; the defaults for what is missing or odd.
  factory ClockStyle.read(Map<String, Object?> menubar) {
    final json = menubar['clock'];
    if (json is! Map) return const ClockStyle();
    bool? flag(String key) => json[key] is bool ? json[key] as bool : null;
    return ClockStyle(
      hour24: flag('hour24'),
      seconds: flag('seconds') ?? false,
      weekday: flag('weekday') ?? true,
      date:
          ClockDate.values.where((d) => d.name == json['date']).firstOrNull ??
          ClockDate.auto,
    );
  }

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

  Map<String, Object?> toJson() => {
    'hour24': ?hour24,
    'seconds': seconds,
    'weekday': weekday,
    'date': date.name,
  };
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

/// Writers of the keys that are not wired yet. Each writes one key and keeps the others.
extension ShellConfigWrites on ConfigStore {
  /// The seconds before the password is asked for (null: never; 15 minutes without the key).
  int? passwordDelay() {
    final all = read('lockscreen');
    if (!all.containsKey('passwordDelay')) return passwordDelayDefault;
    final v = all['passwordDelay'];
    return v is num && v.isFinite && v >= 0 ? v.round() : null;
  }

  /// `null` is written as such: never (an absent key means the default).
  void writePasswordDelay(int? seconds) {
    final all = read('lockscreen');
    all['passwordDelay'] = seconds;
    replace('lockscreen', all);
  }

  /// The saver chosen, and the minutes before it starts (0: never).
  String screenSaver() {
    final v = read('screensaver')['saver'];
    return screenSaverChoices.contains(v) ? '$v' : screenSaverChoices.first;
  }

  int screenSaverAfter() {
    final v = read('screensaver')['minutes'];
    return v is num && v.isFinite && v > 0 ? v.round() : 0;
  }

  void writeScreenSaver(String id) => write('screensaver', 'saver', id);

  void writeScreenSaverMinutes(int minutes) =>
      write('screensaver', 'minutes', minutes);

  void writeDockSizes({required double tile, required double magnified}) {
    final t = DockSizes.tile(tile);
    write('dock', 'tileSize', t);
    write('dock', 'magnifiedSize', DockSizes.magnified(magnified, t));
  }

  void writeLaunchAnimation(LaunchAnimation value) =>
      write('dock', 'launchAnimation', value.name);

  void writeMinimizeToApp(bool value) => write('dock', 'minimizeToApp', value);

  void writeMenuBarAutohide(MenuBarAutohide value) =>
      write('menubar', 'autohide', value.name);

  void writeMenuBarBackground(bool value) =>
      write('menubar', 'background', value);

  void writeRecentItems(int count) => write(
    'menubar',
    'recentItems',
    recentItemChoices.contains(count) ? count : 10,
  );

  void writeClock(ClockStyle style) =>
      write('menubar', 'clock', style.toJson());

  void writeNotificationDefaults({
    PreviewMode? previews,
    GroupingMode? grouping,
  }) {
    if (previews != null) write('notifications', 'previews', previews.name);
    if (grouping != null) write('notifications', 'grouping', grouping.name);
  }

  /// One key of one app in notifications.json `apps`, keeping the app's other keys and the
  /// other apps. A null [value] removes the key (the app then follows the defaults).
  void writeAppNotification(String app, String key, Object? value) {
    final apps = read('notifications')['apps'];
    final all = <String, Object?>{
      if (apps is Map)
        for (final e in apps.entries) '${e.key}': e.value,
    };
    final current = all[app];
    final entry = <String, Object?>{
      if (current is Map)
        for (final e in current.entries) '${e.key}': e.value,
    };
    if (value == null) {
      entry.remove(key);
    } else {
      entry[key] = value;
    }
    all[app] = entry;
    write('notifications', 'apps', all);
  }

  void writeWallpaperFit(WallpaperFit value) =>
      write('wallpaper', 'fit', value.name);
}
