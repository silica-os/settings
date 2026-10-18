// Notifications (ST-NTF-01), Sound (ST-SND-01) and Screen Time (ST-SCT-01); Focus is in focus.dart.
// Real: the apps that sent notifications (silica-daemon's history) and their banner style
// (notifications.json, read by the shell for every notification); the output volume and mute
// (silica-daemon), the output and input devices and the input volume (PipeWire, wpctl); Do Not
// Disturb. The alert sound and volume, the volume feedback and the interface sounds come
// from the sound service (sound.json, #64); the output the effects play through and the
// startup sound (#64), the global notification options (#71) and screen time (#49) wait for
// their backends.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/settings_files.dart';
import '../system/shell_config.dart';
import '../system/tools.dart';
import '../ui/errors.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

/// How an app's notifications appear (the shell's `notifications.apps.<app>.style`).
enum BannerStyle { banners, alerts, none }

String _appKey(String app, String field) => 'notifications.apps.$app.$field';

/// The style saved for [key]; banners by default, as in the shell.
BannerStyle bannerStyleOf(SilicaSettings settings, String key) =>
    settings.getEnum(
      _appKey(key, 'style'),
      BannerStyle.values,
      fallback: BannerStyle.banners,
    );

/// A field of an app in the notification settings, or null.
Object? appValue(SilicaSettings settings, String key, String field) =>
    settings.raw(_appKey(key, field));

/// The previews saved for all apps; always by default, as in the shell.
PreviewMode previewModeOf(Object? name) =>
    PreviewMode.values.where((m) => m.name == name).firstOrNull ??
    PreviewMode.always;

/// Saves [style] for [key].
void saveBannerStyle(SilicaSettings settings, String key, BannerStyle style) =>
    settings.writeAppNotification(key, 'style', style.name);

/// The apps that have notification settings and are not in the daemon's history any more.
List<NotifyingApp> savedApps(SilicaSettings settings) {
  const prefix = 'notifications.apps.';
  final keys = <String>{};
  for (final key in settings.withPrefix(prefix).keys) {
    final dot = key.lastIndexOf('.');
    if (dot > prefix.length) keys.add(key.substring(prefix.length, dot));
  }
  return [for (final key in keys) NotifyingApp(key: key, name: key)];
}

/// The rounded square of an app without its icon: its initial on gray.
class AppInitialTile extends StatelessWidget {
  const AppInitialTile({super.key, required this.name, this.size = 24});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.24),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA9A9AE), Color(0xFF8A8A90)],
      ),
    ),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: settingsText(
        size * 0.5,
        const Color(0xFFFFFFFF),
        weight: FontWeight.w600,
      ),
    ),
  );
}

class NotificationsPane extends StatefulWidget {
  const NotificationsPane({super.key, required this.open});

  final void Function(SubPaneId sub, String detail) open;

  @override
  State<NotificationsPane> createState() => _NotificationsPaneState();
}

class _NotificationsPaneState extends State<NotificationsPane> {
  List<NotifyingApp>? _apps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_apps == null) _load();
  }

  Future<void> _load() async {
    final services = ServicesScope.of(context);
    final fromDaemon = await services.tools.notifyingApps();
    if (!mounted) return;
    final all = {for (final a in fromDaemon) a.key: a};
    for (final a in savedApps(services.settings)) {
      all.putIfAbsent(a.key, () => a);
    }
    setState(
      () => _apps = all.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).settings;
    final apps = _apps ?? const <NotifyingApp>[];
    String summary(BannerStyle s) => switch (s) {
      BannerStyle.banners => l.notificationsStyleBanners,
      BannerStyle.alerts => l.notificationsStyleAlerts,
      BannerStyle.none => l.notificationsStyleOff,
    };
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.notifications.symbol,
          tint: PaneId.notifications.tint,
          title: l.paneNotifications,
          description: l.notificationsDescription,
        ),
        SettingsGroup(
          heading: l.notificationsCenter,
          description: l.notificationsCenterHelp,
          children: [
            PopUpRow<PreviewMode>(
              key: const ValueKey('previews'),
              title: l.notificationsPreviews,
              items: [
                PopUpItem(PreviewMode.always, l.notificationsPreviewsAlways),
                PopUpItem(PreviewMode.unlocked, l.notificationsWhenUnlocked),
                PopUpItem(PreviewMode.never, l.notificationsPreviewsNever),
              ],
              value: previewModeOf(config.raw('notifications.previews')),
              onChanged: (v) =>
                  setState(() => config.writeNotificationDefaults(previews: v)),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.notifications,
          children: [
            ValueRow(title: l.notificationsShowWhen),
            SwitchRow(
              title: l.notificationsWhenSleeping,
              value: false,
              indent: 30,
            ),
            SwitchRow(
              title: l.notificationsWhenLocked,
              value: true,
              indent: 30,
            ),
            SwitchRow(
              title: l.notificationsWhenMirroring,
              value: false,
              indent: 30,
            ),
          ],
        ),
        SettingsGroup(
          heading: l.notificationsApps,
          footer: l.notificationsAppsHelp,
          children: [
            if (_apps != null && apps.isEmpty)
              ValueRow(title: l.notificationsAppsNone),
            for (final app in apps)
              NavRow(
                key: ValueKey('app ${app.key}'),
                title: app.name,
                subtitle: summary(bannerStyleOf(config, app.key)),
                leading: AppInitialTile(name: app.name),
                onTap: () => widget.open(
                  SubPaneId.notificationApp,
                  encodeAppDetail(app.key, app.name),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One app's notifications: allowed or not, and banners that leave by themselves or stay.
class NotificationAppPane extends StatefulWidget {
  const NotificationAppPane({super.key, required this.detail});
  final String detail;

  @override
  State<NotificationAppPane> createState() => _NotificationAppPaneState();
}

class _NotificationAppPaneState extends State<NotificationAppPane> {
  /// The style chosen before notifications were turned off, to bring back.
  BannerStyle _lastShown = BannerStyle.banners;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).settings;
    final (key, name) = appDetail(widget.detail);
    final style = bannerStyleOf(config, key);
    if (style != BannerStyle.none) _lastShown = style;
    void set(BannerStyle s) => setState(() => saveBannerStyle(config, key, s));
    return PanePage(
      children: [
        GroupBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                AppInitialTile(name: name, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: RowTitles(title: l.notificationsAllow, subtitle: name),
                ),
                AmalfiSwitch(
                  key: const ValueKey('allow notifications'),
                  value: style != BannerStyle.none,
                  size: AmalfiControlSize.small,
                  semanticLabel: l.notificationsAllow,
                  onChanged: (on) => set(on ? _lastShown : BannerStyle.none),
                ),
              ],
            ),
          ),
        ),
        SettingsGroup(
          footer: l.notificationsStyleHelp,
          children: [
            ValueRow(
              title: l.notificationsAlertStyle,
              alignTop: true,
              trailing: SettingsRadioGroup<BannerStyle>(
                key: const ValueKey('alert style'),
                options: [
                  RadioOption(
                    BannerStyle.banners,
                    l.notificationsStyleTemporary,
                    enabled: style != BannerStyle.none,
                  ),
                  RadioOption(
                    BannerStyle.alerts,
                    l.notificationsStylePersistent,
                    enabled: style != BannerStyle.none,
                  ),
                ],
                value: style == BannerStyle.none ? _lastShown : style,
                onChanged: style == BannerStyle.none ? null : set,
              ),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            SwitchRow(
              key: const ValueKey('show in center'),
              title: l.notificationsInCenter,
              value: appValue(config, key, 'showInCenter') != false,
              onChanged: style == BannerStyle.none
                  ? null
                  : (v) => setState(
                      () => config.writeAppNotification(
                        key,
                        'showInCenter',
                        v ? null : false,
                      ),
                    ),
            ),
            SwitchRow(
              key: const ValueKey('app sound'),
              title: l.notificationsSound,
              value: appValue(config, key, 'sound') != false,
              onChanged: style == BannerStyle.none
                  ? null
                  : (v) => setState(
                      () => config.writeAppNotification(
                        key,
                        'sound',
                        v ? null : false,
                      ),
                    ),
            ),
            PopUpRow<AppPreviewMode>(
              key: const ValueKey('app previews'),
              title: l.notificationsPreviews,
              items: [
                PopUpItem(
                  AppPreviewMode.byDefault,
                  l.notificationsPreviewsDefault,
                ),
                PopUpItem(AppPreviewMode.always, l.notificationsPreviewsAlways),
                PopUpItem(AppPreviewMode.unlocked, l.notificationsWhenUnlocked),
                PopUpItem(AppPreviewMode.never, l.notificationsPreviewsNever),
              ],
              value:
                  AppPreviewMode.values
                      .where(
                        (m) =>
                            m != AppPreviewMode.byDefault &&
                            m.name == appValue(config, key, 'previews'),
                      )
                      .firstOrNull ??
                  AppPreviewMode.byDefault,
              onChanged: style == BannerStyle.none
                  ? null
                  : (v) => setState(
                      () => config.writeAppNotification(
                        key,
                        'previews',
                        v == AppPreviewMode.byDefault ? null : v.name,
                      ),
                    ),
            ),
            PopUpRow<AppGrouping>(
              key: const ValueKey('app grouping'),
              title: l.notificationsGrouping,
              items: [
                PopUpItem(AppGrouping.auto, l.appearanceAutomaticChoice),
                PopUpItem(AppGrouping.app, l.notificationsGroupByApp),
                PopUpItem(AppGrouping.off, l.notificationsStyleOff),
              ],
              value:
                  AppGrouping.values
                      .where((g) => g.name == appValue(config, key, 'grouping'))
                      .firstOrNull ??
                  AppGrouping.auto,
              onChanged: style == BannerStyle.none
                  ? null
                  : (v) => setState(
                      () => config.writeAppNotification(
                        key,
                        'grouping',
                        v == AppGrouping.auto ? null : v.name,
                      ),
                    ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.notifications,
          children: [SwitchRow(title: l.notificationsBadges, value: true)],
        ),
      ],
    );
  }
}

/// The type of an audio device, from its name (PipeWire's description).
String audioType(AppLocalizations l, String name) {
  final n = name.toLowerCase();
  if (n.contains('hdmi')) return 'HDMI';
  if (n.contains('displayport')) return 'DisplayPort';
  if (n.contains('usb')) return 'USB';
  if (n.contains('bluetooth') || n.contains('bluez')) return l.paneBluetooth;
  if (n.contains('virtual') || n.contains('dummy') || n.contains('null')) {
    return l.soundVirtual;
  }
  return l.soundBuiltIn;
}

/// The alert silica-daemon plays when sound.json has none.
const String defaultAlert = 'alert-crystal';

/// `alert-woodblock` → `Woodblock`.
String alertLabel(String name) {
  final bare = name.startsWith('alert-') ? name.substring(6) : name;
  final words = bare.replaceAll('-', ' ');
  return words.isEmpty ? name : words[0].toUpperCase() + words.substring(1);
}

class SoundPane extends StatefulWidget {
  const SoundPane({super.key});

  @override
  State<SoundPane> createState() => _SoundPaneState();
}

class _SoundPaneState extends State<SoundPane> {
  bool _input = false;
  AudioDevices _devices = const AudioDevices();
  double? _inputVolume;
  double? _outputVolume;
  String? _error;
  Timer? _poll;
  SystemTools? _tools;
  bool? _uiSounds;
  List<String> _alerts = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tools ??= ServicesScope.of(context).tools;
    if (_poll == null) {
      final system = ServicesScope.of(context).system;
      system.uiSoundsEnabled().then((on) {
        if (mounted) setState(() => _uiSounds = on);
      });
      system.alertSounds().then((alerts) {
        if (mounted) setState(() => _alerts = alerts);
      });
      _load();
      // Devices come and go (headphones, a display): read them again every 3 s.
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// The alert sound: a pop-up of the service's `alert-*` sounds that plays the one chosen
  /// (sound.json `alert`), and a button that plays it again.
  Widget _alertRow(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final saved = services.config.text(
      'sound',
      'alert',
      fallback: defaultAlert,
    );
    final names = [
      ..._alerts,
      if (_alerts.isNotEmpty && !_alerts.contains(saved)) saved,
    ];
    return ValueRow(
      key: const ValueKey('alert sound'),
      title: l.soundAlert,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmalfiPushButton(
            key: const ValueKey('play alert'),
            label: l.soundAlertPlay,
            size: AmalfiControlSize.small,
            onPressed: names.isEmpty
                ? null
                : () => services.system.playAlert(saved),
          ),
          const SizedBox(width: 10),
          SettingsPopUp<String>(
            items: [
              for (final name in names) PopUpItem(name, alertLabel(name)),
            ],
            value: names.contains(saved) ? saved : null,
            semanticLabel: l.soundAlert,
            onChanged: names.isEmpty
                ? null
                : (name) {
                    services.config.write('sound', 'alert', name);
                    services.system.playAlert(name);
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    final devices = await _tools!.audioDevices();
    if (mounted) setState(() => _devices = devices);
  }

  Future<void> _run(Future<ToolError?> change) async {
    final error = await change;
    if (!mounted) return;
    setState(
      () => _error = error == null
          ? null
          : errorText(AppLocalizations.of(context), error),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final system = ServicesScope.of(context).system;
    final config = ServicesScope.of(context).config;
    final tools = _tools!;
    return SystemStateBuilder(
      builder: (context, state) {
        final list = _input ? _devices.inputs : _devices.outputs;
        final input = _devices.defaultInput;
        final output = _devices.outputs.where((d) => d.isDefault).firstOrNull;
        return PanePage(
          children: [
            SettingsGroup(
              heading: l.soundEffects,
              footer: _uiSounds == null
                  ? l.soundNoService
                  : l.soundEffectsPending,
              children: [
                _alertRow(context),
                Unavailable(
                  child: PopUpRow<int>(
                    title: l.soundEffectsThrough,
                    items: [PopUpItem(0, l.soundSelectedOutput)],
                    value: 0,
                    onChanged: (_) {},
                  ),
                ),
                SliderRow(
                  key: const ValueKey('alert volume'),
                  title: l.soundAlertVolume,
                  value: config.alertVolume,
                  onChanged: _uiSounds == null
                      ? null
                      : (v) {
                          config.writeAlertVolume(v);
                          setState(() {});
                        },
                  // The alert at its new volume, once the slider is let go.
                  onChangeEnd: _uiSounds == null
                      ? null
                      : (_) => system.playAlert(''),
                ),
                Unavailable(
                  child: SwitchRow(title: l.soundStartup, value: true),
                ),
                if (_uiSounds case final on?)
                  SwitchRow(
                    key: const ValueKey('ui sounds'),
                    title: l.soundInterface,
                    value: on,
                    onChanged: (v) async {
                      setState(() => _uiSounds = v);
                      await system.setUiSoundsEnabled(v);
                      final now = await system.uiSoundsEnabled();
                      if (mounted) setState(() => _uiSounds = now);
                    },
                  )
                else
                  Unavailable(
                    child: SwitchRow(title: l.soundInterface, value: true),
                  ),
                SwitchRow(
                  key: const ValueKey('volume feedback'),
                  title: l.soundVolumeFeedback,
                  value: config.flag(
                    'sound',
                    'volumeFeedback',
                    fallback: false,
                  ),
                  onChanged: _uiSounds == null
                      ? null
                      : (on) {
                          config.write('sound', 'volumeFeedback', on);
                          setState(() {});
                        },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(l.soundOutputInput),
                GroupBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: AmalfiSegmentedControl(
                            key: const ValueKey('output input'),
                            segments: [
                              AmalfiSegment.text(l.soundOutput),
                              AmalfiSegment.text(l.soundInput),
                            ],
                            selected: {_input ? 1 : 0},
                            onChanged: (s) =>
                                setState(() => _input = s.contains(1)),
                          ),
                        ),
                      ),
                      _DeviceTable(
                        devices: list,
                        nameHeader: l.soundName,
                        typeHeader: l.soundType,
                        empty: state.audioAvailable || list.isNotEmpty
                            ? l.soundNoDevices
                            : l.soundNoAudio,
                        type: (d) => audioType(l, d.name),
                        onChoose: (d) => _run(tools.setDefaultAudio(d.id)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error case final error?) ErrorLine(error),
            if (!_input)
              // The daemon's audio when it has it; otherwise PipeWire's default output
              // directly.
              GroupBox(
                child: state.audioAvailable || output == null
                    ? _VolumeRow(
                        title: l.soundOutputVolume,
                        sliderKey: const ValueKey('output volume'),
                        value: state.volume,
                        enabled: state.audioAvailable,
                        onChanged: (v) => system.setVolume(v),
                        mute: AmalfiCheckbox(
                          key: const ValueKey('mute'),
                          value: state.muted,
                          label: l.soundMute,

                          onChanged: state.audioAvailable
                              ? (v) => system.setMuted(v)
                              : null,
                        ),
                      )
                    : _VolumeRow(
                        title: l.soundOutputVolume,
                        sliderKey: const ValueKey('output volume'),
                        value: _outputVolume ?? output.volume,
                        enabled: true,
                        onChanged: (v) {
                          setState(() => _outputVolume = v);
                          tools.setAudioVolume(output.id, v);
                        },
                        onChangeEnd: (_) {
                          setState(() => _outputVolume = null);
                          _load();
                        },
                        mute: AmalfiCheckbox(
                          key: const ValueKey('mute'),
                          value: output.muted,
                          label: l.soundMute,

                          onChanged: (v) =>
                              _run(tools.setAudioMuted(output.id, v)),
                        ),
                      ),
              )
            else
              GroupBox(
                child: _VolumeRow(
                  title: l.soundInputVolume,
                  sliderKey: const ValueKey('input volume'),
                  value: _inputVolume ?? input?.volume ?? 0,
                  enabled: input != null,
                  onChanged: (v) {
                    setState(() => _inputVolume = v);
                    if (input != null) tools.setAudioVolume(input.id, v);
                  },
                  onChangeEnd: (_) {
                    setState(() => _inputVolume = null);
                    _load();
                  },
                  mute: AmalfiCheckbox(
                    key: const ValueKey('input mute'),
                    value: input?.muted ?? false,
                    label: l.soundMute,

                    onChanged: input == null
                        ? null
                        : (v) => _run(tools.setAudioMuted(input.id, v)),
                  ),
                ),
              ),
            if (!state.audioAvailable && output == null && !_input)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  l.soundNoAudio,
                  style: settingsText(11, colors.secondary),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The output volume row: the title on the left, the slider between two speaker symbols on
/// the right, mute under it (ST-SND-01).
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.title,
    required this.sliderKey,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.mute,
    this.onChangeEnd,
  });

  final String title;
  final Key sliderKey;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Widget mute;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: RowTitles(title: title)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsSymbol('volume-0', color: colors.secondary, size: 12),
                  const SizedBox(width: 6),
                  LabelledSlider(
                    key: sliderKey,
                    value: value.clamp(0, 1),
                    width: 240,
                    enabled: enabled,
                    semanticLabel: title,
                    onChanged: enabled ? onChanged : null,
                    onChangeEnd: onChangeEnd,
                  ),
                  const SizedBox(width: 6),
                  SettingsSymbol('volume', color: colors.secondary, size: 14),
                ],
              ),
              const SizedBox(height: 6),
              mute,
            ],
          ),
        ],
      ),
    );
  }
}

/// The devices as a two-column table (name, type), the default one selected; a click makes
/// a device the default (ST-SND-01).
class _DeviceTable extends StatelessWidget {
  const _DeviceTable({
    required this.devices,
    required this.nameHeader,
    required this.typeHeader,
    required this.empty,
    required this.type,
    required this.onChoose,
  });

  final List<AudioDevice> devices;
  final String nameHeader;
  final String typeHeader;
  final String empty;
  final String Function(AudioDevice) type;
  final ValueChanged<AudioDevice> onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final tokens = AmalfiTheme.of(context).colors;
    final header = tokens.surfaceSunken;
    final stripe = tokens.surfaceWindow;
    final chosen = tokens.accentAmalfiSoft;
    Widget row(String a, String b, TextStyle style) => Row(
      children: [
        Expanded(
          flex: 335,
          child: Text(
            a,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Expanded(
          flex: 186,
          child: Text(
            b,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(SettingsMetrics.groupRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: header,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: row(
              nameHeader,
              typeHeader,
              settingsText(11, colors.secondary),
            ),
          ),
          if (devices.isEmpty)
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: Text(empty, style: settingsText(13, colors.secondary)),
            ),
          for (final (i, d) in devices.indexed)
            GestureDetector(
              key: ValueKey('audio ${d.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onChoose(d),
              child: Container(
                height: 24,
                color: d.isDefault
                    ? chosen
                    : (i.isOdd ? stripe : const Color(0x00000000)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Semantics(
                  selected: d.isDefault,
                  button: true,
                  child: row(d.name, type(d), settingsText(13, colors.text)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScreenTimePane extends StatelessWidget {
  const ScreenTimePane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.screenTimeActivity,
          unavailable: true,
          issue: Issues.screenTime,
          children: [
            NavRow(
              title: l.screenTimeAppUsage,
              symbol: 'hourglass',
              tint: const Color(0xFF8B5CF6),
              onTap: () {},
            ),
            NavRow(
              title: l.screenTimeNotifications,
              symbol: 'bell',
              tint: const Color(0xFFF0562E),
              onTap: () {},
            ),
          ],
        ),
        SettingsGroup(
          heading: l.screenTimeLimits,
          unavailable: true,
          issue: Issues.screenTime,
          children: [
            NavRow(
              title: l.screenTimeDowntime,
              symbol: 'moon',
              tint: const Color(0xFF8B5CF6),
              onTap: () {},
            ),
            NavRow(
              title: l.screenTimeAppLimits,
              symbol: 'hourglass',
              tint: const Color(0xFFFF9500),
              onTap: () {},
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.screenTime,
          children: [SwitchRow(title: l.screenTimeAppActivity, value: false)],
        ),
      ],
    );
  }
}
