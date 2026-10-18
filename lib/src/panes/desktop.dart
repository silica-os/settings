// Menu Bar (ST-CCT-01), Desktop & Dock (ST-DSK-01..04) and Wallpaper (ST-WLP-01/02); Displays
// is in displays.dart. Real: the menu bar's status items (menubar.json, watched by the shell),
// the Dock's options (dock.json, watched by the shell: magnification, recent apps,
// auto-hide, minimize effect, indicators, position), the default web browser (xdg-settings)
// and the wallpaper (wallpaper.json, watched by the shell: the choice and the fill mode). The rest
// waits for Ossido and the shell: each group's footer names the issue.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/amalfi_wallpapers.dart';
import '../system/config.dart';
import '../system/shell_config.dart';
import '../system/tools.dart';
import '../ui/errors.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';
import 'input.dart' show showShortcuts;
import 'screen_saver.dart' show showScreenSaver;

/// The sound item of the menu bar (menubar.json `sound`).
enum SoundItem { always, active, never }

/// A checkbox, an icon tile and a name: one menu bar control.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    super.key,
    required this.title,
    required this.symbol,
    required this.tint,
    required this.checked,
    required this.onChecked,
    this.trailing,
  });

  final String title;
  final String symbol;
  final Color tint;
  final bool checked;
  final ValueChanged<bool>? onChecked;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          AmalfiCheckbox(value: checked, onChanged: onChecked),
          const SizedBox(width: 10),
          IconTile(symbol: symbol, tint: tint, size: 20),
          const SizedBox(width: 8),
          Expanded(child: RowTitles(title: title)),
          ?trailing,
        ],
      ),
    ),
  );
}

class MenuBarPane extends StatefulWidget {
  const MenuBarPane({super.key});

  @override
  State<MenuBarPane> createState() => _MenuBarPaneState();
}

class _MenuBarPaneState extends State<MenuBarPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    // The shell's defaults (shell/lib/menubar/menubar_config.dart).
    final sound =
        SoundItem.values
            .where(
              (s) => s.name == config.text('menubar', 'sound', fallback: ''),
            )
            .firstOrNull ??
        SoundItem.active;
    final autohide =
        MenuBarAutohide.values
            .where(
              (v) => v.name == config.text('menubar', 'autohide', fallback: ''),
            )
            .firstOrNull ??
        MenuBarAutohide.fullscreen;
    final bluetooth = config.flag('menubar', 'bluetooth', fallback: false);
    final battery = config.flag('menubar', 'battery', fallback: true);
    final percent = config.flag('menubar', 'batteryPercent', fallback: false);
    final recent = switch (config.read('menubar')['recentItems']) {
      final int n => n,
      _ => 10,
    };
    void set(String key, Object value) =>
        setState(() => config.write('menubar', key, value));
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            footer: l.menuBarLive,
            children: [
              PopUpRow<MenuBarAutohide>(
                key: const ValueKey('menubar autohide'),
                title: l.menuBarAutoHide,
                items: [
                  PopUpItem(MenuBarAutohide.never, l.menuBarNever),
                  PopUpItem(MenuBarAutohide.fullscreen, l.menuBarInFullScreen),
                  PopUpItem(MenuBarAutohide.always, l.menuBarHideAlways),
                ],
                value: autohide,
                onChanged: (v) => set('autohide', v.name),
              ),
              SwitchRow(
                key: const ValueKey('menubar background'),
                title: l.menuBarBackground,
                value: config.flag('menubar', 'background', fallback: false),
                onChanged: (v) => set('background', v),
              ),
            ],
          ),
          SettingsGroup(
            children: [
              PopUpRow<int>(
                key: const ValueKey('menubar recent items'),
                title: l.menuBarRecentItems,
                items: [
                  for (final n in recentItemChoices)
                    PopUpItem(n, n == 0 ? l.menuBarRecentNone : '$n'),
                ],
                value: recentItemChoices.contains(recent) ? recent : 10,
                onChanged: (n) => setState(() => config.writeRecentItems(n)),
              ),
            ],
          ),
          SettingsGroup(
            heading: l.menuBarControls,
            description: l.menuBarControlsHelp,
            footer: l.menuBarLive,
            children: [
              _ControlRow(
                key: const ValueKey('menubar bluetooth'),
                title: l.paneBluetooth,
                symbol: PaneId.bluetooth.symbol,
                tint: PaneId.bluetooth.tint,
                checked: bluetooth,
                onChecked: (v) => set('bluetooth', v),
              ),
              _ControlRow(
                key: const ValueKey('menubar sound'),
                title: l.paneSound,
                symbol: PaneId.sound.symbol,
                tint: PaneId.sound.tint,
                checked: sound != SoundItem.never,
                onChecked: (v) => set(
                  'sound',
                  v ? SoundItem.active.name : SoundItem.never.name,
                ),
                trailing: sound == SoundItem.never
                    ? null
                    : SettingsPopUp<SoundItem>(
                        key: const ValueKey('menubar sound when'),
                        items: [
                          PopUpItem(SoundItem.always, l.menuBarAlways),
                          PopUpItem(SoundItem.active, l.menuBarShowWhenActive),
                        ],
                        value: sound,
                        semanticLabel: l.paneSound,
                        onChanged: (v) => set('sound', v.name),
                      ),
              ),
              _ControlRow(
                key: const ValueKey('menubar battery'),
                title: l.paneBattery,
                symbol: PaneId.battery.symbol,
                tint: PaneId.battery.tint,
                checked: battery,
                onChecked: (v) => set('battery', v),
              ),
              SwitchRow(
                key: const ValueKey('menubar battery percent'),
                title: l.menuBarBatteryPercent,
                value: percent,
                indent: 30,
                onChanged: battery ? (v) => set('batteryPercent', v) : null,
              ),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            issue: Issues.menuBar,
            children: [
              _ControlRow(
                title: l.paneWifi,
                symbol: PaneId.wifi.symbol,
                tint: PaneId.wifi.tint,
                checked: true,
                onChecked: (_) {},
              ),
              _ControlRow(
                title: l.paneFocus,
                symbol: PaneId.focus.symbol,
                tint: PaneId.focus.tint,
                checked: true,
                onChecked: (_) {},
              ),
              _ControlRow(
                title: l.paneDisplays,
                symbol: PaneId.displays.symbol,
                tint: PaneId.displays.tint,
                checked: true,
                onChecked: (_) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where the Dock sits (dock.json `position`); only the bottom is drawn by the shell today.
enum DockPosition { left, bottom, right }

/// The effect that takes a window into the Dock (dock.json `minimizeEffect`).
enum MinimizeEffect { genie, scale }

/// What a double click on a title bar does (dock.json `titleBarDoubleClick`, read by
/// silica_ui's `WindowDragArea`).
enum TitleBarAction { zoom, minimize, none }

class DesktopDockPane extends StatefulWidget {
  const DesktopDockPane({super.key});

  @override
  State<DesktopDockPane> createState() => _DesktopDockPaneState();
}

class _DesktopDockPaneState extends State<DesktopDockPane> {
  List<AppEntry> _browsers = const [];
  String _browser = '';
  String? _error;
  bool _loaded = false;
  Timer? _watch;
  Map<String, Object?>? _seen;

  // The shell writes dock.json too (dragging the Dock separator changes `tileSize`); the
  // pane re-reads it twice a second and redraws when the file's content changed.
  void _startWatching(ConfigStore config) {
    _seen = config.read('dock');
    _watch = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = config.read('dock');
      if (!mapEquals(now, _seen)) {
        _seen = now;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _startWatching(ServicesScope.of(context).config);
      _loadBrowsers();
    }
  }

  Future<void> _loadBrowsers() async {
    final tools = ServicesScope.of(context).tools;
    final list = await tools.browsers();
    final current = await tools.defaultBrowser();
    if (mounted) {
      setState(() {
        _browsers = list;
        _browser = current;
      });
    }
  }

  T _named<T extends Enum>(
    ConfigStore config,
    String key,
    List<T> values,
    T fallback,
  ) =>
      values
          .where((v) => v.name == config.text('dock', key, fallback: ''))
          .firstOrNull ??
      fallback;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final config = services.config;
    // The shell's defaults (shell/lib/dock/options.dart).
    bool flag(String key, bool fallback) =>
        config.flag('dock', key, fallback: fallback);
    void set(String key, Object value) =>
        setState(() => config.write('dock', key, value));
    final tile = DockSizes.tile(
      config.number('dock', 'tileSize', fallback: DockSizes.tileDefault),
    );
    final magnified = DockSizes.magnified(
      config.number(
        'dock',
        'magnifiedSize',
        fallback: DockSizes.magnifiedDefault,
      ),
      tile,
    );
    final position = _named(
      config,
      'position',
      DockPosition.values,
      DockPosition.bottom,
    );
    final effect = _named(
      config,
      'minimizeEffect',
      MinimizeEffect.values,
      MinimizeEffect.genie,
    );
    final doubleClick = _named(
      config,
      'titleBarDoubleClick',
      TitleBarAction.values,
      TitleBarAction.zoom,
    );
    final browsers = [
      ..._browsers,
      if (_browser.isNotEmpty && !_browsers.any((b) => b.id == _browser))
        AppEntry(id: _browser, name: _browser.replaceAll('.desktop', '')),
    ];
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.dockSection,
          children: [
            SliderRow(
              key: const ValueKey('dock size'),
              title: l.dockSize,
              value: tile.toDouble(),
              min: DockSizes.tileMin,
              max: DockSizes.tileMax,
              labels: [l.dockSmall, l.dockLarge],
              onChanged: (v) {
                final next = DockSizes.tile(v);
                if (next == tile) return;
                setState(
                  () => config.writeDockSizes(
                    tile: next.toDouble(),
                    magnified: magnified.toDouble(),
                  ),
                );
              },
            ),
            SliderRow(
              key: const ValueKey('dock magnification size'),
              title: l.dockMagnificationSize,
              value: magnified.toDouble(),
              // A non-empty range even at the largest size (the slider divides by it).
              min: math.min(tile.toDouble(), DockSizes.magnifiedMax - 1),
              max: DockSizes.magnifiedMax,
              labels: [l.dockSmall, l.dockLarge],
              onChanged: flag('magnify', false)
                  ? (v) {
                      final next = DockSizes.magnified(v, tile);
                      if (next == magnified) return;
                      setState(
                        () => config.writeDockSizes(
                          tile: tile.toDouble(),
                          magnified: next.toDouble(),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
        SettingsGroup(
          footer: l.dockLiveNote,
          children: [
            PopUpRow<DockPosition>(
              key: const ValueKey('dock position'),
              title: l.dockPosition,
              items: [
                // The side Docks are not drawn yet (silica-desktop#72, #73).
                PopUpItem(DockPosition.left, l.dockLeft, enabled: false),
                PopUpItem(DockPosition.bottom, l.dockBottom),
                PopUpItem(DockPosition.right, l.dockRight, enabled: false),
              ],
              value: position,
              onChanged: (v) => set('position', v.name),
            ),
            PopUpRow<MinimizeEffect>(
              key: const ValueKey('dock minimize effect'),
              title: l.dockMinimizeEffect,
              items: [
                PopUpItem(MinimizeEffect.genie, l.dockGenie),
                PopUpItem(MinimizeEffect.scale, l.dockScale),
              ],
              value: effect,
              onChanged: (v) => set('minimizeEffect', v.name),
            ),
            PopUpRow<TitleBarAction>(
              key: const ValueKey('dock double click'),
              title: l.dockDoubleClick,
              items: [
                PopUpItem(TitleBarAction.zoom, l.dockZoom),
                PopUpItem(TitleBarAction.minimize, l.dockMinimiseAction),
                PopUpItem(TitleBarAction.none, l.dockDoubleClickNothing),
              ],
              value: doubleClick,
              onChanged: (v) => set('titleBarDoubleClick', v.name),
            ),
            SwitchRow(
              key: const ValueKey('dock minimize into icon'),
              title: l.dockMinimizeIntoIcon,
              value: flag('minimizeToApp', false),
              onChanged: (v) => set('minimizeToApp', v),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            SwitchRow(
              key: const ValueKey('dock magnify'),
              title: l.dockMagnification,
              value: flag('magnify', false),
              onChanged: (v) => set('magnify', v),
            ),
            SwitchRow(
              key: const ValueKey('dock autohide'),
              title: l.dockAutoHide,
              value: flag('autohide', false),
              onChanged: (v) => set('autohide', v),
            ),
            SwitchRow(
              key: const ValueKey('dock animate'),
              title: l.dockAnimate,
              value:
                  config.text('dock', 'launchAnimation', fallback: '') !=
                  'none',
              onChanged: (v) => setState(
                () => config.writeLaunchAnimation(
                  v ? LaunchAnimation.bounce : LaunchAnimation.none,
                ),
              ),
            ),
            SwitchRow(
              key: const ValueKey('dock indicators'),
              title: l.dockIndicators,
              value: flag('indicators', true),
              onChanged: (v) => set('indicators', v),
            ),
            SwitchRow(
              key: const ValueKey('dock recents'),
              title: l.dockRecents,
              value: flag('recents', false),
              onChanged: (v) => set('recents', v),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.desktopSection,
          unavailable: true,
          issue: Issues.desktopStage,
          children: [
            PopUpRow<int>(
              title: l.desktopClickWallpaper,
              items: [PopUpItem(0, l.desktopOnlyInStage)],
              value: 0,
              onChanged: (_) {},
            ),
            SwitchRow(title: l.desktopStage, value: false),
          ],
        ),
        SettingsGroup(
          children: [
            PopUpRow<String>(
              key: const ValueKey('default browser'),
              title: l.desktopDefaultBrowser,
              items: [for (final b in browsers) PopUpItem(b.id, b.name)],
              value: _browser.isEmpty ? null : _browser,
              onChanged: browsers.isEmpty
                  ? null
                  : (id) async {
                      final error = await services.tools.setDefaultBrowser(id);
                      if (!context.mounted) return;
                      setState(
                        () =>
                            _error = error == null ? null : errorText(l, error),
                      );
                      await _loadBrowsers();
                    },
            ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
        SettingsGroup(
          heading: l.panoramaSection,
          unavailable: true,
          issue: Issues.panorama,
          children: [
            SwitchRow(title: l.panoramaRearrange, value: true),
            SwitchRow(title: l.panoramaSwitchToApp, value: true),
            SwitchRow(title: l.panoramaGroupByApp, value: false),
            SwitchRow(title: l.panoramaSeparateSpaces, value: true),
          ],
        ),
        ButtonBar(
          buttons: [
            AmalfiPushButton(
              key: const ValueKey('dock shortcuts'),
              label: l.dockShortcutsButton,
              size: AmalfiControlSize.small,
              onPressed: () => showShortcuts(context),
            ),
            AmalfiPushButton(
              key: const ValueKey('hot corners'),
              label: l.dockHotCorners,
              size: AmalfiControlSize.small,
              onPressed: () => showHotCorners(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a hot corner does (hotcorners.json, read by Ossido).
enum HotCorner {
  none,
  panorama,
  appWindows,
  desktop,
  notifications,
  launcher,
  controlCenter,
  search,
}

/// The four corners, with the hotcorners.json key of each.
enum CornerPlace { topLeft, topRight, bottomLeft, bottomRight }

/// The action of [place] in hotcorners.json; none when missing or unknown.
HotCorner hotCornerOf(ConfigStore config, CornerPlace place) =>
    HotCorner.values
        .where((c) => c.name == config.read('hotcorners')[place.name])
        .firstOrNull ??
    HotCorner.none;

/// The hot corners sheet (ST-DSK-04): 711 × 193, four 269 × 24 pop-ups around a 100 × 69
/// desktop preview, Done. Ossido runs the chosen action when the pointer reaches the corner.
Future<void> showHotCorners(BuildContext context) {
  final l = AppLocalizations.of(context);
  final config = ServicesScope.of(context).config;
  String label(HotCorner c) => switch (c) {
    HotCorner.none => l.hotCornerNone,
    HotCorner.panorama => l.hotCornerPanorama,
    HotCorner.appWindows => l.hotCornerAppWindows,
    HotCorner.desktop => l.hotCornerDesktop,
    HotCorner.notifications => l.hotCornerNotifications,
    HotCorner.launcher => l.hotCornerLauncher,
    HotCorner.controlCenter => l.hotCornerControlCenter,
    HotCorner.search => l.hotCornerSearch,
  };
  return showAmalfiSheet<void>(
    context,
    semanticLabel: l.dockHotCorners,
    builder: (context, sheet) {
      final colors = SettingsColors.of(context);
      return StatefulBuilder(
        builder: (context, setState) {
          Widget corner(CornerPlace place) => SizedBox(
            width: 269,
            height: 24,
            child: AmalfiPopUpButton<HotCorner>(
              key: ValueKey('hot corner ${place.name}'),
              items: [
                for (final c in HotCorner.values)
                  AmalfiPopUpItem<HotCorner>(value: c, label: label(c)),
              ],
              value: hotCornerOf(config, place),
              size: AmalfiControlSize.small,
              width: 269,
              semanticLabel: place.name,
              onChanged: (c) => setState(
                () => config.write(
                  'hotcorners',
                  place.name,
                  c == HotCorner.none ? null : c.name,
                ),
              ),
            ),
          );
          return SizedBox(
            width: 711,
            height: 193,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            corner(CornerPlace.topLeft),
                            corner(CornerPlace.bottomLeft),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 69,
                              decoration: BoxDecoration(
                                color: colors.group,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.separator),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            corner(CornerPlace.topRight),
                            corner(CornerPlace.bottomRight),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.hotCornersHelp,
                          style: settingsText(11, colors.secondary),
                        ),
                      ),
                      AmalfiPushButton(
                        key: const ValueKey('hot corners done'),
                        label: l.done,
                        variant: AmalfiPushButtonVariant.primary,
                        onPressed: sheet.close,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// A wallpaper choice as written in wallpaper.json.
sealed class WallpaperOption {
  const WallpaperOption();
  Map<String, Object?> get json;
}

class DefaultWallpaper extends WallpaperOption {
  const DefaultWallpaper();
  @override
  Map<String, Object?> get json => const {};
}

/// A wallpaper of the Amalfi set (silica-wallpapers): written as `{"wallpaper": "<id>"}`.
class AmalfiWallpaperOption extends WallpaperOption {
  const AmalfiWallpaperOption(this.info);
  final AmalfiWallpaperInfo info;
  @override
  Map<String, Object?> get json => {'wallpaper': info.id};
}

class ColorWallpaper extends WallpaperOption {
  const ColorWallpaper(this.color);
  final Color color;

  String get hex =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Map<String, Object?> get json => {'color': hex};
}

class ImageWallpaper extends WallpaperOption {
  const ImageWallpaper(this.path);
  final String path;
  @override
  Map<String, Object?> get json => {'image': path};
}

/// The current choice, as the shell reads it.
///
/// With the Amalfi set installed ([amalfi]) the choice is one of it: the `wallpaper` id, else
/// the default (Ravello) when nothing else is chosen, as the shell does.
WallpaperOption readWallpaper(
  Map<String, Object?> json, {
  List<AmalfiWallpaperInfo> amalfi = const [],
}) {
  if (json['image'] case final String path) return ImageWallpaper(path);
  if (json['color'] case final String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value != null && hex.replaceFirst('#', '').length == 6) {
      return ColorWallpaper(Color(0xFF000000 | value));
    }
  }
  if (amalfi.isNotEmpty) {
    final id = json['wallpaper'];
    for (final wanted in [id, defaultWallpaperId]) {
      for (final w in amalfi) {
        if (w.id == wanted) return AmalfiWallpaperOption(w);
      }
    }
    return AmalfiWallpaperOption(amalfi.first);
  }
  return const DefaultWallpaper();
}

/// The solid colours (one category is plain colours; the reference sessions used `#7a7b80`;
/// the others are ours).
const List<Color> wallpaperColors = [
  Color(0xFF7A7B80),
  Color(0xFF1F2A44),
  Color(0xFF2E5E4E),
  Color(0xFF6B3A5B),
  Color(0xFFB86F4A),
  Color(0xFF101012),
  Color(0xFFE5E5EA),
  Color(0xFF3A6EA5),
];

class WallpaperPane extends StatefulWidget {
  const WallpaperPane({super.key});

  @override
  State<WallpaperPane> createState() => _WallpaperPaneState();
}

class _WallpaperPaneState extends State<WallpaperPane> {
  List<String>? _pictures;
  List<AmalfiWallpaperInfo>? _amalfi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final env = ServicesScope.of(context).env;
    _pictures ??= _findPictures(env);
    _amalfi ??= loadAmalfiWallpapers(env: env);
  }

  /// Images in the user's pictures folder and the system's backgrounds (first level, at most
  /// 40).
  static List<String> _findPictures(Map<String, String> env) {
    final dirs = xdgUserDirs(env);
    final pictures = dirs['PICTURES'] ?? '${env['HOME'] ?? ''}/Pictures';
    final files = <String>[];
    for (final folder in [
      pictures,
      '${env['HOME'] ?? ''}/.local/share/backgrounds',
    ]) {
      try {
        final dir = Directory(folder);
        if (!dir.existsSync()) continue;
        files.addAll(
          [
            for (final e in dir.listSync())
              if (e is File &&
                  RegExp(
                    r'\.(png|jpe?g|webp)$',
                    caseSensitive: false,
                  ).hasMatch(e.path))
                e.path,
          ]..sort(),
        );
      } on FileSystemException {
        continue;
      }
    }
    return files.take(40).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final config = ServicesScope.of(context).config;
    final amalfi = _amalfi ?? const <AmalfiWallpaperInfo>[];
    final current = readWallpaper(config.read('wallpaper'), amalfi: amalfi);
    void choose(WallpaperOption option) => setState(
      () => config.replace('wallpaper', {
        // The fit is a separate choice; a new picture keeps it.
        'fit': ?config.read('wallpaper')['fit'],
        ...option.json,
      }),
    );
    final fit =
        WallpaperFit.values
            .where((f) => f.name == config.read('wallpaper')['fit'])
            .firstOrNull ??
        WallpaperFit.fill;
    final pictures = _pictures ?? const [];
    return PanePage(
      children: [
        // The current wallpaper: a 160 × 100 preview, its name with the fill pop-up and the
        // all-spaces switch beside it (ST-WLP-02).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(
              key: const ValueKey('current wallpaper'),
              option: current,
              width: 160,
              height: 100,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SettingsGroup(
                children: [
                  ValueRow(
                    title: _name(l, current),
                    trailing: SettingsPopUp<WallpaperFit>(
                      key: const ValueKey('wallpaper fit'),
                      items: [
                        PopUpItem(WallpaperFit.fill, l.wallpaperFill),
                        PopUpItem(WallpaperFit.fit, l.wallpaperFit),
                        PopUpItem(WallpaperFit.stretch, l.wallpaperStretch),
                        PopUpItem(WallpaperFit.center, l.wallpaperCenter),
                        PopUpItem(WallpaperFit.tile, l.wallpaperTile),
                      ],
                      value: fit,
                      semanticLabel: l.wallpaperFill,
                      // A colour or the generated gradient has nothing to fit.
                      onChanged: current is ColorWallpaper
                          ? null
                          : (v) => setState(() => config.writeWallpaperFit(v)),
                    ),
                  ),
                  Unavailable(
                    child: SwitchRow(title: l.wallpaperAllSpaces, value: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l.wallpaperNote,
                style: settingsText(11, colors.secondary, height: 1.3),
              ),
            ),
            const SizedBox(width: 10),
            AmalfiPushButton(
              key: const ValueKey('screen saver button'),
              label: l.wallpaperScreenSaver,
              size: AmalfiControlSize.small,
              onPressed: () => showScreenSaver(context),
            ),
          ],
        ),
        Container(height: 1, color: colors.separator),
        if (amalfi.isNotEmpty)
          _Category(
            title: l.wallpaperAmalfi,
            options: [for (final w in amalfi) AmalfiWallpaperOption(w)],
            current: current,
            onChoose: choose,
            name: (o) => _name(l, o),
          )
        else
          _Category(
            title: l.wallpaperSilica,
            options: const [DefaultWallpaper()],
            current: current,
            onChoose: choose,
            name: (o) => _name(l, o),
          ),
        _Category(
          title: l.wallpaperColors,
          options: [for (final c in wallpaperColors) ColorWallpaper(c)],
          current: current,
          onChoose: choose,
          name: (o) => _name(l, o),
        ),
        if (pictures.isNotEmpty)
          _Category(
            title: l.wallpaperPictures,
            options: [for (final p in pictures) ImageWallpaper(p)],
            current: current,
            onChoose: choose,
            name: (o) => _name(l, o),
          ),
      ],
    );
  }

  static String _name(AppLocalizations l, WallpaperOption o) => switch (o) {
    DefaultWallpaper() => l.wallpaperSilicaName,
    AmalfiWallpaperOption(:final info) => info.title,
    ColorWallpaper(:final hex) => hex,
    ImageWallpaper(:final path) => path.split('/').last,
  };
}

/// A category: its heading with "Show all (n)", then a row of 107 × 71 thumbnails with their
/// names (ST-WLP-02).
class _Category extends StatefulWidget {
  const _Category({
    required this.title,
    required this.options,
    required this.current,
    required this.onChoose,
    required this.name,
  });

  final String title;
  final List<WallpaperOption> options;
  final WallpaperOption current;
  final ValueChanged<WallpaperOption> onChoose;
  final String Function(WallpaperOption) name;

  @override
  State<_Category> createState() => _CategoryState();
}

class _CategoryState extends State<_Category> {
  bool _all = false;

  bool _same(WallpaperOption a, WallpaperOption b) => switch ((a, b)) {
    (DefaultWallpaper(), DefaultWallpaper()) => true,
    (AmalfiWallpaperOption(:final info), final AmalfiWallpaperOption other) =>
      info.id == other.info.id,
    (ColorWallpaper(:final hex), final ColorWallpaper other) =>
      hex == other.hex,
    (ImageWallpaper(:final path), final ImageWallpaper other) =>
      path == other.path,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    final shown = _all ? widget.options : widget.options.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: settingsText(13, colors.text, weight: FontWeight.w600),
                ),
              ),
              if (widget.options.length > 4)
                GestureDetector(
                  key: ValueKey('show all ${widget.title}'),
                  onTap: () => setState(() => _all = !_all),
                  child: Text(
                    _all
                        ? l.wallpaperShowFewer
                        : l.wallpaperShowAll(widget.options.length),
                    style: settingsText(11, colors.secondary),
                  ),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final option in shown)
              GestureDetector(
                key: ValueKey('wallpaper ${option.json}'),
                onTap: () => widget.onChoose(option),
                child: SizedBox(
                  width: 113,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            width: 3,
                            color: _same(option, widget.current)
                                ? accent
                                : const Color(0x00000000),
                          ),
                        ),
                        child: _Thumb(option: option, width: 101, height: 65),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.name(option),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: settingsText(11, colors.text),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    super.key,
    required this.option,
    required this.width,
    required this.height,
  });

  final WallpaperOption option;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = SettingsColors.of(context).dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: switch (option) {
          // The shell draws the Silica wallpaper: a diagonal gradient (silica-brand).
          DefaultWallpaper() => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [
                        Color(0xFF0B1030),
                        Color(0xFF2A1446),
                        Color(0xFF0A2A2E),
                      ]
                    : const [
                        Color(0xFF8EC5FF),
                        Color(0xFFF9C6D9),
                        Color(0xFFFFE2B0),
                      ],
              ),
            ),
          ),
          // The 640 px preview of the appearance's variant.
          AmalfiWallpaperOption(:final info) => Image.file(
            File(
              (dark ? info.darkPreview : info.lightPreview) ??
                  info.image(dark: dark),
            ),
            fit: BoxFit.cover,
            cacheWidth: (width * 2).round(),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: Color(0xFF7A7B80)),
          ),
          ColorWallpaper(:final color) => ColoredBox(color: color),
          ImageWallpaper(:final path) => Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: (width * 2).round(),
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: Color(0xFF7A7B80)),
          ),
        },
      ),
    );
  }
}
