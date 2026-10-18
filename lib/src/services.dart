// What the panes reach: the system backend (silica-daemon), the configuration files, the
// machine information and the environment. One [Services] for the window, given to the tree by
// [ServicesScope].

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'accent.dart';
import 'startup.dart';
import 'system/config.dart';
import 'system/host.dart';
import 'system/system.dart';
import 'system/tools.dart';
import 'system/tools_host.dart';

/// The size of the sidebar icons (Appearance › Windows).
enum SidebarIconSize { small, medium, large }

/// When scroll bars show (Appearance › Windows).
enum ScrollBarsMode { automatic, whenScrolling, always }

/// The text highlight colour: the accent's, or one of the accents by name.
enum HighlightColor {
  automatic,
  blue,
  purple,
  pink,
  red,
  orange,
  yellow,
  green,
  graphite,
}

/// What a click in the scroll bar's track does (Appearance › Windows).
enum ScrollClick { page, spot }

/// The style of icons and widgets (Appearance › Theme); `standard` is Default.
enum IconStyle {
  standard('default'),
  dark('dark'),
  clear('clear'),
  tinted('tinted');

  const IconStyle(this.wire);

  /// The value in theme.json.
  final String wire;
}

T _named<T extends Enum>(List<T> values, String name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

class Services {
  Services({
    required this.system,
    required this.config,
    required this.host,
    required this.env,
    SystemTools? tools,
    SilicaSettings? settings,
  }) : tools = tools ?? HostSystemTools(env: env),
       settings = settings ?? SilicaSettings.instance,
       accent = ValueNotifier(
         Accent.parse(config.text('theme', 'accent', fallback: '')),
       ),
       highlight = ValueNotifier(
         _named(
           HighlightColor.values,
           config.text('theme', 'highlight', fallback: ''),
           HighlightColor.automatic,
         ),
       ),
       sidebarIconSize = ValueNotifier(
         _named(
           SidebarIconSize.values,
           config.text('theme', 'sidebarIconSize', fallback: ''),
           SidebarIconSize.medium,
         ),
       ),
       scrollBars = ValueNotifier(
         _named(
           ScrollBarsMode.values,
           config.text('theme', 'scrollBars', fallback: ''),
           ScrollBarsMode.automatic,
         ),
       ),
       scrollClick = ValueNotifier(
         _named(
           ScrollClick.values,
           config.text('theme', 'scrollClick', fallback: ''),
           ScrollClick.page,
         ),
       ),
       iconStyle = ValueNotifier(
         IconStyle.values
                 .where(
                   (v) =>
                       v.wire ==
                       config.text('theme', 'iconStyle', fallback: ''),
                 )
                 .firstOrNull ??
             IconStyle.standard,
       ),
       keyboardNavigation = ValueNotifier(
         config.read('theme')['keyboardNavigation'] == true,
       ),
       doubleClickMs = ValueNotifier(
         _doubleClick(config.read('theme')['doubleClickMs']),
       ),
       reduceTransparency = ValueNotifier(
         config.read('theme')['reduceTransparency'] == true,
       ),
       reduceMotion = ValueNotifier(
         config.read('theme')['reduceMotion'] == true,
       ),
       increaseContrast = ValueNotifier(
         config.read('theme')['increaseContrast'] == true,
       ),
       textScale = ValueNotifier(_textScale(config.read('theme')['textScale'])),
       cursorSize = ValueNotifier(
         _cursorSize(config.read('theme')['cursorSize']),
       ),
       glass = ValueNotifier(_glassLevel(config.read('theme')['glass'])) {
    // This window and the apps that start now draw with the saved look at once.
    SilicaSystemLook.apply(systemLook);
  }

  final SystemBackend system;
  final ConfigStore config;

  /// The system settings service (the shell's keys: `dock.*`, `menubar.*`, `wallpaper.*`,
  /// `lockscreen.*`, `screensaver.*`, `notifications.*`).
  final SilicaSettings settings;
  final HostReader host;
  final Map<String, String> env;

  /// The machine: the OS, the hardware and the user do not change while the window is open.
  /// Empty at first; [loadHostInfo] fills it after the first frame, the graphics adapters
  /// (pci.ids) only when About asks ([loadGraphics]). Read through [HostInfoScope].
  final ValueNotifier<HostInfo> hostInfo = ValueNotifier(const HostInfo());

  bool _infoLoading = false;
  bool _graphicsLoading = false;

  /// Reads the machine information once, a moment after the first frame.
  Future<void> loadHostInfo() async {
    if (_infoLoading) return;
    _infoLoading = true;
    await Future<void>.value();
    final graphics = hostInfo.value.graphics;
    hostInfo.value = host.read(withGraphics: false).withGraphics(graphics);
    startupMark('host info read');
  }

  /// Names the graphics adapters (About); read once.
  Future<void> loadGraphics() async {
    if (_graphicsLoading) return;
    _graphicsLoading = true;
    await Future<void>.value();
    hostInfo.value = hostInfo.value.withGraphics(host.graphics());
    startupMark('graphics read');
  }

  /// The system services Settings drives directly (NetworkManager, PipeWire, systemd's
  /// hostnamed, timedated and localed, BlueZ, power profiles, the default apps).
  final SystemTools tools;

  /// The accent the window draws with (theme.json, changed by the Appearance pane).
  final ValueNotifier<Accent> accent;

  /// The text highlight colour (theme.json `highlight`).
  final ValueNotifier<HighlightColor> highlight;

  /// The sidebar icon size (theme.json `sidebarIconSize`).
  final ValueNotifier<SidebarIconSize> sidebarIconSize;

  /// When scroll bars show (theme.json `scrollBars`).
  final ValueNotifier<ScrollBarsMode> scrollBars;

  /// What a click in the scroll bar's track does (theme.json `scrollClick`).
  final ValueNotifier<ScrollClick> scrollClick;

  /// The style of icons and widgets (theme.json `iconStyle`).
  final ValueNotifier<IconStyle> iconStyle;

  /// How tinted the glass is, 0 clear to 1 tinted (theme.json `glass`; Ossido draws it).
  final ValueNotifier<double> glass;

  /// Tab reaches every control (theme.json `keyboardNavigation`).
  final ValueNotifier<bool> keyboardNavigation;

  /// The longest time between the two clicks of a double click, in ms (theme.json
  /// `doubleClickMs`, 150-1000).
  final ValueNotifier<int> doubleClickMs;

  /// Glass drawn opaque (theme.json `reduceTransparency`; Ossido reads it too).
  final ValueNotifier<bool> reduceTransparency;

  /// Animations skipped (theme.json `reduceMotion`; Ossido reads it too).
  final ValueNotifier<bool> reduceMotion;

  /// The high-contrast palette (theme.json `increaseContrast`; silica_ui draws it).
  final ValueNotifier<bool> increaseContrast;

  /// The size of the apps' text relative to the design's (theme.json `textScale`, 1–1.5).
  final ValueNotifier<double> textScale;

  /// The pointer's size (theme.json `cursorSize`; Ossido draws the cursor at that size).
  final ValueNotifier<int> cursorSize;

  static const int doubleClickSlowest = 1000;
  static const int doubleClickFastest = 150;

  /// The text factor, 1 to 1.5 (Larger Text).
  static double _textScale(Object? value) =>
      value is num && value.isFinite ? value.toDouble().clamp(1.0, 1.5) : 1.0;

  /// The pointer's size in points, 16 to 128; the default 24.
  static int _cursorSize(Object? value) => value is num && value.isFinite
      ? value.round().clamp(cursorSizeMin, cursorSizeMax)
      : cursorSizeDefault;

  static int _doubleClick(Object? value) => value is num && value.isFinite
      ? value.round().clamp(doubleClickFastest, doubleClickSlowest)
      : 300;

  static double _glassLevel(Object? value) =>
      value is num && value.isFinite ? value.toDouble().clamp(0.0, 1.0) : 0.5;

  /// Everything the window's look depends on.
  Listenable get look => Listenable.merge([
    accent,
    highlight,
    sidebarIconSize,
    scrollBars,
    scrollClick,
    iconStyle,
    glass,
    keyboardNavigation,
    doubleClickMs,
    reduceTransparency,
    reduceMotion,
    increaseContrast,
    textScale,
    cursorSize,
  ]);

  /// The look as silica_ui draws it: set in this window at once, kept by silica-daemon for
  /// the other apps and the shell (`SetLook`), which follow live.
  SystemLook get systemLook => SystemLook(
    accent:
        SystemLook.parseAccent(accent.value.name) ?? SilicaAccent.multicolor,
    highlight: SystemLook.parseAccent(highlight.value.name),
    sidebarIconSize: SystemSidebarIconSize.parse(sidebarIconSize.value.name),
    scrollBars: SystemScrollBars.parse(scrollBars.value.name),
    scrollClick: SystemScrollClick.parse(scrollClick.value.name),
    iconStyle: SystemIconStyle.parse(iconStyle.value.wire),
    glass: glass.value,
    keyboardNavigation: keyboardNavigation.value,
    doubleClickMs: doubleClickMs.value,
    reduceTransparency: reduceTransparency.value,
    reduceMotion: reduceMotion.value,
    increaseContrast: increaseContrast.value,
    textScale: textScale.value,
  );

  void _saveLook(String key, Object value) {
    config.write('theme', key, value);
    SilicaSystemLook.apply(systemLook);
    unawaited(system.setLook({key: value}));
  }

  void setAccent(Accent value) {
    accent.value = value;
    _saveLook('accent', value.name);
  }

  void setHighlight(HighlightColor value) {
    highlight.value = value;
    _saveLook('highlight', value.name);
  }

  void setSidebarIconSize(SidebarIconSize value) {
    sidebarIconSize.value = value;
    _saveLook('sidebarIconSize', value.name);
  }

  void setScrollBars(ScrollBarsMode value) {
    scrollBars.value = value;
    _saveLook('scrollBars', value.name);
  }

  void setScrollClick(ScrollClick value) {
    scrollClick.value = value;
    _saveLook('scrollClick', value.name);
  }

  void setIconStyle(IconStyle value) {
    iconStyle.value = value;
    _saveLook('iconStyle', value.wire);
  }

  void setKeyboardNavigation(bool value) {
    keyboardNavigation.value = value;
    _saveLook('keyboardNavigation', value);
  }

  void setReduceTransparency(bool value) {
    reduceTransparency.value = value;
    _saveLook('reduceTransparency', value);
  }

  void setReduceMotion(bool value) {
    reduceMotion.value = value;
    _saveLook('reduceMotion', value);
  }

  void setIncreaseContrast(bool value) {
    increaseContrast.value = value;
    _saveLook('increaseContrast', value);
  }

  void setTextScale(double value) {
    final scale = _textScale(value);
    if (scale == textScale.value) return;
    textScale.value = scale;
    _saveLook('textScale', scale);
  }

  /// Ossido watches theme.json: no daemon call, the apps do not draw the pointer.
  void setCursorSize(int value) {
    final size = _cursorSize(value);
    if (size == cursorSize.value) return;
    cursorSize.value = size;
    config.write('theme', 'cursorSize', size);
  }

  void setDoubleClickMs(int value) {
    final ms = _doubleClick(value);
    if (ms == doubleClickMs.value) return;
    doubleClickMs.value = ms;
    _saveLook('doubleClickMs', ms);
  }

  void setGlass(double value) {
    final level = _glassLevel(value);
    if (level == glass.value) return;
    glass.value = level;
    _saveLook('glass', level);
  }
}

/// The pointer sizes Settings offers, in points (Ossido accepts 16–128).
const int cursorSizeMin = 24;
const int cursorSizeMax = 96;
const int cursorSizeDefault = 24;

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final Services services;

  static Services of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'no ServicesScope above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope old) => old.services != services;
}

/// The machine information, rebuilding its readers when it arrives.
class HostInfoScope extends InheritedNotifier<ValueNotifier<HostInfo>> {
  const HostInfoScope({
    super.key,
    required ValueNotifier<HostInfo> info,
    required super.child,
  }) : super(notifier: info);

  static HostInfo of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HostInfoScope>();
    assert(scope != null, 'no HostInfoScope above this widget');
    return scope!.notifier!.value;
  }
}

/// Rebuilds with every system state (Wi-Fi, Bluetooth, audio…), from the backend's stream.
class SystemStateBuilder extends StatefulWidget {
  const SystemStateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, SystemState state) builder;

  @override
  State<SystemStateBuilder> createState() => _SystemStateBuilderState();
}

class _SystemStateBuilderState extends State<SystemStateBuilder> {
  SystemState _state = const SystemState();
  StreamSubscription<SystemState>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= ServicesScope.of(context).system.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}

/// Rebuilds with whether the session's polkit authentication agent is registered
/// (silica-daemon, `Authentication1.Registered`): `null` until the daemon answers. Changes
/// that polkit protects (time zone, computer name, language) are enabled only when it is
/// `true`.
class AuthenticationBuilder extends StatefulWidget {
  const AuthenticationBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool? registered) builder;

  @override
  State<AuthenticationBuilder> createState() => _AuthenticationBuilderState();
}

class _AuthenticationBuilderState extends State<AuthenticationBuilder> {
  bool? _registered;
  StreamSubscription<bool>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= ServicesScope.of(context).system.authenticationRegistered
        .listen((registered) {
          if (mounted) setState(() => _registered = registered);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _registered);
}
