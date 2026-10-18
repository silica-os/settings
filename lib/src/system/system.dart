// The system state and actions Settings changes, from silica-daemon
// (`dev.frascella.Silica.System1`, silica-desktop docs/daemon.md): Wi-Fi, Bluetooth, battery,
// audio, Do Not Disturb and the dark appearance. [SystemBackend] is the interface the panes
// use; [DaemonBackend] talks to the daemon over the embedder's silica/dbus channel, tests use
// a fake.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dbus.dart';
import 'displays.dart';

const String systemName = 'dev.frascella.Silica';
const String systemPath = '/dev/frascella/Silica/System1';
const String systemInterface = 'dev.frascella.Silica.System1';

/// A snapshot of the system state. Missing sources have `available` false; [reachable] is
/// false when the daemon itself does not answer.
@immutable
class SystemState {
  const SystemState({
    this.reachable = false,
    this.wifiAvailable = false,
    this.wifiEnabled = false,
    this.wifiSsid = '',
    this.wifiStrength = 0,
    this.wired = false,
    this.bluetoothAvailable = false,
    this.bluetoothPowered = false,
    this.batteryPresent = false,
    this.batteryPercent = 0,
    this.batteryCharging = false,
    this.audioAvailable = false,
    this.volume = 0,
    this.muted = false,
    this.audioName = '',
    this.doNotDisturb = false,
    this.dark = false,
    this.displays = '',
    this.night = const NightLight(),
    this.focus = '',
    this.focusName = '',
    this.focusSymbol = '',
    this.focusApps = const [],
    this.focusPeople = const [],
    this.preventSleep = false,
    this.inhibited = false,
    this.appearanceMode = '',
    this.touchpad = false,
    this.mouse = false,
    this.textReplacements = const [],
  });

  final bool reachable;

  /// The text replacements apps apply while typing: (shortcut, phrase).
  final List<(String, String)> textReplacements;
  final bool wifiAvailable;
  final bool wifiEnabled;
  final String wifiSsid;
  final int wifiStrength;
  final bool wired;
  final bool bluetoothAvailable;
  final bool bluetoothPowered;
  final bool batteryPresent;
  final double batteryPercent;
  final bool batteryCharging;
  final bool audioAvailable;
  final double volume;
  final bool muted;
  final String audioName;
  final bool doNotDisturb;
  final bool dark;

  /// The displays, as the JSON of Ossido's `output.list` (`displays`); changes with every
  /// display plugged in and every new mode, scale or rotation. Read with
  /// [OutputInfo.parseList].
  final String displays;
  final NightLight night;

  /// The active Focus: its id (`dnd`, or a mode of focus.json), empty when off; the mode's
  /// name and symbol, and the apps and people whose notifications still come through.
  final String focus;
  final String focusName;
  final String focusSymbol;
  final List<String> focusApps;
  final List<String> focusPeople;

  /// power.json `preventSleep` as the daemon read it, and whether its logind inhibitor is held.
  final bool preventSleep;
  final bool inhibited;

  /// `light`, `dark` or `auto`; empty when the daemon does not say (`dark` then decides).
  final String appearanceMode;

  /// A touchpad / another pointer is connected (`input.touchpad`, `input.mouse`, reported by
  /// Ossido): Settings shows its Trackpad pane only with a touchpad.
  final bool touchpad;
  final bool mouse;

  /// From the daemon's `State()` dictionary (flat keys).
  static SystemState fromDict(Map<Object?, Object?> d) {
    bool flag(String key) => d[key] == true;
    double number(String key) {
      final value = d[key];
      return value is num && value.isFinite ? value.toDouble() : 0;
    }

    String text(String key) => d[key] is String ? d[key] as String : '';
    List<String> strings(String key) {
      final value = d[key];
      return value is List
          ? [
              for (final e in value)
                if (e is String) e,
            ]
          : const [];
    }

    return SystemState(
      reachable: true,
      wifiAvailable: flag('wifi.available'),
      wifiEnabled: flag('wifi.enabled'),
      wifiSsid: text('wifi.ssid'),
      wifiStrength: number('wifi.strength').round().clamp(0, 100),
      wired: flag('wifi.wired'),
      bluetoothAvailable: flag('bluetooth.available'),
      bluetoothPowered: flag('bluetooth.powered'),
      batteryPresent: flag('battery.present'),
      batteryPercent: number('battery.percent').clamp(0, 100).toDouble(),
      batteryCharging: flag('battery.charging'),
      audioAvailable: flag('audio.available'),
      volume: number('audio.volume').clamp(0, 1).toDouble(),
      muted: flag('audio.muted'),
      audioName: text('audio.name'),
      doNotDisturb: flag('dnd'),
      dark: flag('appearance.dark'),
      displays: text('displays'),
      night: NightLight(
        enabled: flag('nightlight.enabled'),
        temperature: number('nightlight.temperature') > 0
            ? number('nightlight.temperature').round().clamp(
                NightLight.minTemperature,
                NightLight.maxTemperature,
              )
            : NightLight.defaultTemperature,
        schedule:
            const {
              'off',
              'sunset',
              'custom',
            }.contains(text('nightlight.schedule'))
            ? text('nightlight.schedule')
            : 'off',
        from: NightLight.validTime(text('nightlight.from'))
            ? text('nightlight.from')
            : '21:00',
        to: NightLight.validTime(text('nightlight.to'))
            ? text('nightlight.to')
            : '07:00',
        active: flag('nightlight.active'),
      ),
      focus: text('focus'),
      focusName: text('focus.name'),
      focusSymbol: text('focus.symbol'),
      focusApps: strings('focus.allowedApps'),
      focusPeople: strings('focus.allowedPeople'),
      preventSleep: flag('power.preventSleep'),
      inhibited: flag('power.inhibited'),
      appearanceMode: text('appearance.mode'),
      touchpad: flag('input.touchpad'),
      mouse: flag('input.mouse'),
      textReplacements: [
        if (d['text.replacements'] case final List list)
          for (final item in list)
            if (item is List &&
                item.length == 2 &&
                item[0] is String &&
                item[1] is String)
              (item[0] as String, item[1] as String),
      ],
    );
  }
}

/// A Wi-Fi network as the daemon lists it.
@immutable
class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.strength,
    required this.secured,
    required this.saved,
    required this.inUse,
  });

  final String ssid;
  final int strength;
  final bool secured;
  final bool saved;
  final bool inUse;
}

/// A paired Bluetooth device.
@immutable
class BluetoothDevice {
  const BluetoothDevice({
    required this.address,
    required this.name,
    required this.icon,
    required this.connected,
  });

  final String address;
  final String name;

  /// The BlueZ icon name (`audio-headphones`, `input-mouse`…).
  final String icon;
  final bool connected;
}

/// An audio output.
@immutable
class AudioOutput {
  const AudioOutput({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final String name;
  final bool isDefault;
}

/// What Settings reads and changes in the system.
abstract class SystemBackend {
  /// The current state, then every change.
  Stream<SystemState> get states;

  Future<SystemState> state();

  /// `light`, `dark` or `auto` (dark from sunset to sunrise), kept by the daemon in
  /// appearance.json.
  Future<void> setAppearanceMode(String mode);
  Future<void> setWifiEnabled(bool enabled);
  Future<List<WifiNetwork>> wifiNetworks();

  /// Only saved networks: a new network needs a password, which the daemon cannot take yet.
  Future<void> connectWifi(String ssid);
  Future<void> setBluetoothPowered(bool powered);
  Future<List<BluetoothDevice>> bluetoothDevices();
  Future<void> connectBluetooth(String address, {required bool connect});
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Future<List<AudioOutput>> audioOutputs();
  Future<void> setAudioOutput(int id);
  Future<void> setDoNotDisturb(bool enabled);

  /// Turns a Focus on: `dnd`, the id of a mode of focus.json, or empty for none.
  Future<void> setFocus(String id);

  /// The displays (`System1.Outputs`); empty when the compositor does not answer.
  Future<List<OutputInfo>> displayList();

  /// Changes a display (`ConfigureOutput`): applied at once and kept by the compositor. Null
  /// when it took the change, otherwise why not.
  Future<String?> configureOutput(
    String connector, {
    OutputMode? mode,
    double? scale,
    String? transform,
  });

  /// Any of the night light's settings (`SetNightLight`); the others stay. Null when the
  /// daemon took them, otherwise why not.
  Future<String?> setNightLight({
    bool? enabled,
    int? temperature,
    String? schedule,
    String? from,
    String? to,
  });

  /// Tells the daemon the Appearance choices apps follow live (`SetLook`: strings, a number for
  /// `glass`). Settings keeps them in theme.json too, so a missing daemon is not an error.
  Future<void> setLook(Map<String, Object> values);

  /// Replaces the text replacements (`SetTextReplacements`, `a(ss)`). Null when the daemon took
  /// them, otherwise why not.
  Future<String?> setTextReplacements(List<(String, String)> list);

  /// "Play interface sound effects" (`dev.frascella.Silica.Sound1`); null when the daemon
  /// has no sound service.
  Future<bool?> uiSoundsEnabled();
  Future<void> setUiSoundsEnabled(bool enabled);

  /// The `alert-*` sounds the sound service found, sorted; empty without the service.
  Future<List<String>> alertSounds();

  /// Plays an alert sound at the alert volume, for the preview; empty `name`: the chosen one.
  Future<void> playAlert(String name);

  /// Whether the session's polkit authentication agent is registered
  /// (`dev.frascella.Silica.Authentication1.Registered`): the current value, then every
  /// change. False when the daemon does not answer.
  Stream<bool> get authenticationRegistered;
}

/// silica-daemon over D-Bus. Errors (no daemon, a missing source) become an unreachable state
/// or empty lists: Settings shows what it can, never crashes.
class DaemonBackend implements SystemBackend {
  DaemonBackend({DBus? bus}) : _bus = bus ?? DBus.instance;

  final DBus _bus;
  StreamController<SystemState>? _controller;
  StreamSubscription<DBusSignal>? _signals;

  /// The latest state on the shared stream, replayed to every later listener: the snapshot
  /// is read once, when the first listener arrives, and a pane opened after it would
  /// otherwise wait for the next `Changed` signal.
  SystemState? _latest;

  Future<List<Object?>> _call(
    String method, {
    String signature = '',
    List<Object?> args = const [],
  }) => _bus.call(
    destination: systemName,
    path: systemPath,
    interface: systemInterface,
    method: method,
    signature: signature,
    args: args,
  );

  @override
  Future<SystemState> state() async {
    try {
      final reply = await _call('State');
      final first = reply.isEmpty ? null : reply.first;
      return first is Map ? SystemState.fromDict(first) : const SystemState();
    } on PlatformException {
      return const SystemState();
    } on MissingPluginException {
      return const SystemState();
    }
  }

  @override
  Stream<SystemState> get states async* {
    final latest = _latest;
    if (latest != null) yield latest;
    yield* _shared;
  }

  Stream<SystemState> get _shared {
    final existing = _controller;
    if (existing != null) return existing.stream;
    late final StreamController<SystemState> controller;
    controller = StreamController<SystemState>.broadcast(
      onListen: () async {
        final snapshot = await state();
        _latest = snapshot;
        controller.add(snapshot);
        _signals = _bus
            .signals(
              sender: systemName,
              path: systemPath,
              interface: systemInterface,
              member: 'Changed',
            )
            .listen(
              (signal) {
                final first = signal.args.isEmpty ? null : signal.args.first;
                if (first is Map) {
                  final changed = SystemState.fromDict(first);
                  _latest = changed;
                  controller.add(changed);
                }
              },
              onError: (Object _) {
                // No signals outside Silica: the snapshot read at the start stays.
              },
            );
      },
      onCancel: () async {
        await _signals?.cancel();
        _signals = null;
        _controller = null;
        _latest = null;
      },
    );
    _controller = controller;
    return controller.stream;
  }

  Future<void> _set(String method, String signature, Object? value) async {
    try {
      await _call(method, signature: signature, args: [value]);
    } on PlatformException {
      // A missing source: the state stays as the daemon reports it.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  Future<List<Object?>> _list(String method) async {
    try {
      final reply = await _call(method);
      final first = reply.isEmpty ? null : reply.first;
      return first is List ? first : const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<void> setAppearanceMode(String mode) =>
      _set('SetAppearanceMode', 's', mode);

  @override
  Future<void> setWifiEnabled(bool enabled) =>
      _set('SetWifiEnabled', 'b', enabled);

  @override
  Future<List<WifiNetwork>> wifiNetworks() async => [
    for (final row in await _list('WifiNetworks'))
      if (row is List && row.length >= 5)
        WifiNetwork(
          ssid: '${row[0]}',
          strength: row[1] is num ? (row[1] as num).round().clamp(0, 100) : 0,
          secured: row[2] == true,
          saved: row[3] == true,
          inUse: row[4] == true,
        ),
  ];

  @override
  Future<void> connectWifi(String ssid) => _set('ConnectWifi', 's', ssid);

  @override
  Future<void> setBluetoothPowered(bool powered) =>
      _set('SetBluetoothPowered', 'b', powered);

  @override
  Future<List<BluetoothDevice>> bluetoothDevices() async => [
    for (final row in await _list('BluetoothDevices'))
      if (row is List && row.length >= 4)
        BluetoothDevice(
          address: '${row[0]}',
          name: '${row[1]}',
          icon: '${row[2]}',
          connected: row[3] == true,
        ),
  ];

  @override
  Future<void> connectBluetooth(String address, {required bool connect}) async {
    try {
      await _call(
        'ConnectBluetooth',
        signature: 'sb',
        args: [address, connect],
      );
    } on PlatformException {
      // The device did not answer: the list shows its real state on the next read.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  @override
  Future<void> setVolume(double volume) =>
      _set('SetVolume', 'd', volume.clamp(0, 1).toDouble());

  @override
  Future<void> setMuted(bool muted) => _set('SetMuted', 'b', muted);

  @override
  Future<List<AudioOutput>> audioOutputs() async => [
    for (final row in await _list('AudioOutputs'))
      if (row is List && row.length >= 3 && row[0] is num)
        AudioOutput(
          id: (row[0] as num).toInt(),
          name: '${row[1]}',
          isDefault: row[2] == true,
        ),
  ];

  @override
  Future<void> setAudioOutput(int id) => _set('SetAudioOutput', 'u', id);

  @override
  Future<void> setDoNotDisturb(bool enabled) =>
      _set('SetDoNotDisturb', 'b', enabled);

  @override
  Future<void> setFocus(String id) => _set('SetFocus', 's', id);

  @override
  Future<List<OutputInfo>> displayList() async {
    try {
      final reply = await _call('Outputs');
      final first = reply.isEmpty ? null : reply.first;
      return first is String ? OutputInfo.parseList(first) : const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<String?> configureOutput(
    String connector, {
    OutputMode? mode,
    double? scale,
    String? transform,
  }) async {
    try {
      await _call(
        'ConfigureOutput',
        signature: 's',
        args: [
          jsonEncode({
            'connector': connector,
            if (mode != null)
              'mode': {
                'width': mode.width,
                'height': mode.height,
                if (mode.refresh > 0) 'refresh': mode.refresh,
              },
            'scale': ?scale,
            'transform': ?transform,
          }),
        ],
      );
      return null;
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } on MissingPluginException {
      return 'no silica-daemon';
    }
  }

  @override
  Future<String?> setNightLight({
    bool? enabled,
    int? temperature,
    String? schedule,
    String? from,
    String? to,
  }) async {
    try {
      await _call(
        'SetNightLight',
        signature: 'a{sv}',
        args: [
          {
            'enabled': ?enabled,
            'temperature': ?temperature,
            'schedule': ?schedule,
            'from': ?from,
            'to': ?to,
          },
        ],
      );
      return null;
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } on MissingPluginException {
      return 'no silica-daemon';
    }
  }

  @override
  Future<String?> setTextReplacements(List<(String, String)> list) async {
    try {
      await _call(
        'SetTextReplacements',
        signature: 'a(ss)',
        args: [
          [
            for (final (shortcut, phrase) in list) [shortcut, phrase],
          ],
        ],
      );
      return null;
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } on MissingPluginException {
      return 'no silica-daemon';
    }
  }

  @override
  Future<void> setLook(Map<String, Object> values) async {
    try {
      await _call('SetLook', signature: 'a{sv}', args: [values]);
    } on PlatformException {
      // A refused value or no daemon: theme.json has it and the daemon reads it at its start.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  static const String _authPath = '/dev/frascella/Silica/Authentication1';
  static const String _authInterface = 'dev.frascella.Silica.Authentication1';

  Future<bool> _registered() async {
    try {
      final value = await _bus.getProperty(
        destination: systemName,
        path: _authPath,
        interface: _authInterface,
        name: 'Registered',
      );
      return value == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Stream<bool> get authenticationRegistered async* {
    yield await _registered();
    try {
      await for (final _ in _bus.signals(
        sender: systemName,
        path: _authPath,
        interface: 'org.freedesktop.DBus.Properties',
        member: 'PropertiesChanged',
      )) {
        yield await _registered();
      }
    } on PlatformException {
      // No signals: the value read at the start stays.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  static const String _soundPath = '/dev/frascella/Silica/Sound1';
  static const String _soundInterface = 'dev.frascella.Silica.Sound1';

  @override
  Future<bool?> uiSoundsEnabled() async {
    try {
      final reply = await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'UiSoundsEnabled',
      );
      final first = reply.isEmpty ? null : reply.first;
      return first is bool ? first : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<List<String>> alertSounds() async {
    try {
      final reply = await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'AlertSounds',
      );
      final first = reply.isEmpty ? null : reply.first;
      return first is List
          ? [
              for (final name in first)
                if (name is String) name,
            ]
          : const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<void> playAlert(String name) async {
    try {
      await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'PlayAlert',
        signature: 's',
        args: [name],
      );
    } on PlatformException {
      // No such sound or no sound service: nothing plays.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  @override
  Future<void> setUiSoundsEnabled(bool enabled) async {
    try {
      await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'SetUiSoundsEnabled',
        signature: 'b',
        args: [enabled],
      );
    } on PlatformException {
      // No sound service: the switch reads the state again.
    } on MissingPluginException {
      // Outside Silica.
    }
  }
}
