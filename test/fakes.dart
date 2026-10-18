// A fake silica-daemon and a window set up like the real one (832 × 727), for the widget tests.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/app.dart';
import 'package:silica_settings/src/model/navigation.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/services.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/displays.dart';
import 'package:silica_settings/src/system/host.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

class FakeSystem implements SystemBackend {
  FakeSystem([this.current = const SystemState(reachable: true)]);

  SystemState current;
  final StreamController<SystemState> _states =
      StreamController<SystemState>.broadcast();
  final List<String> calls = [];
  List<WifiNetwork> networks = const [];
  List<BluetoothDevice> devices = const [];
  List<AudioOutput> outputs = const [];

  void emit(SystemState state) {
    current = state;
    _states.add(state);
  }

  @override
  Stream<SystemState> get states async* {
    yield current;
    yield* _states.stream;
  }

  @override
  Future<SystemState> state() async => current;

  @override
  Future<void> setLook(Map<String, Object> values) async =>
      calls.add('setLook $values');

  /// What the daemon would answer to a text replacements list (null: it took it).
  String? replacementsError;

  @override
  Future<String?> setTextReplacements(List<(String, String)> list) async {
    calls.add('setTextReplacements $list');
    return replacementsError;
  }

  @override
  Future<void> setAppearanceMode(String mode) async =>
      calls.add('setAppearanceMode $mode');

  @override
  Future<void> setWifiEnabled(bool enabled) async =>
      calls.add('setWifiEnabled $enabled');

  @override
  Future<List<WifiNetwork>> wifiNetworks() async => networks;

  @override
  Future<void> connectWifi(String ssid) async => calls.add('connectWifi $ssid');

  @override
  Future<void> setBluetoothPowered(bool powered) async =>
      calls.add('setBluetoothPowered $powered');

  @override
  Future<List<BluetoothDevice>> bluetoothDevices() async => devices;

  @override
  Future<void> connectBluetooth(
    String address, {
    required bool connect,
  }) async => calls.add('connectBluetooth $address $connect');

  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume');

  @override
  Future<void> setMuted(bool muted) async => calls.add('setMuted $muted');

  @override
  Future<List<AudioOutput>> audioOutputs() async => outputs;

  @override
  Future<void> setAudioOutput(int id) async => calls.add('setAudioOutput $id');

  @override
  Future<void> setDoNotDisturb(bool enabled) async =>
      calls.add('setDoNotDisturb $enabled');

  @override
  Future<void> setFocus(String id) async => calls.add('setFocus $id');

  /// The compositor's displays; empty: it does not answer.
  List<OutputInfo> displays = const [];

  /// Why the compositor refuses the next change (null: it takes it).
  String? displayError;

  /// The state with [displays] in it, as the daemon would emit after a change.
  SystemState get withDisplays => SystemState(
    reachable: true,
    displays: jsonEncode([for (final d in displays) d.toJson()]),
    night: night,
  );

  NightLight night = const NightLight();

  @override
  Future<List<OutputInfo>> displayList() async => displays;

  @override
  Future<String?> configureOutput(
    String connector, {
    OutputMode? mode,
    double? scale,
    String? transform,
  }) async {
    calls.add(
      'configureOutput $connector'
      '${mode == null ? '' : ' ${mode.size}${mode.refresh > 0 ? '@${mode.refresh}' : ''}'}'
      '${scale == null ? '' : ' scale $scale'}'
      '${transform == null ? '' : ' $transform'}',
    );
    if (displayError != null) return displayError;
    displays = [
      for (final d in displays)
        if (d.connector != connector)
          d
        else
          OutputInfo(
            connector: d.connector,
            identity: d.identity,
            make: d.make,
            model: d.model,
            modes: d.modes,
            current: mode == null
                ? d.current
                : d.modes
                          .where(
                            (m) =>
                                m.width == mode.width &&
                                m.height == mode.height &&
                                (mode.refresh == 0 ||
                                    (m.refresh - mode.refresh).abs() < 0.01),
                          )
                          .firstOrNull ??
                      mode,
            scale: scale ?? d.scale,
            transform: transform ?? d.transform,
            enabled: d.enabled,
            primary: d.primary,
          ),
    ];
    emit(withDisplays);
    return null;
  }

  @override
  Future<String?> setNightLight({
    bool? enabled,
    int? temperature,
    String? schedule,
    String? from,
    String? to,
  }) async {
    calls.add(
      'setNightLight${enabled == null ? '' : ' enabled $enabled'}'
      '${temperature == null ? '' : ' temperature $temperature'}'
      '${schedule == null ? '' : ' schedule $schedule'}'
      '${from == null ? '' : ' from $from'}${to == null ? '' : ' to $to'}',
    );
    if (displayError != null) return displayError;
    night = NightLight(
      enabled: enabled ?? night.enabled,
      temperature: temperature ?? night.temperature,
      schedule: schedule ?? night.schedule,
      from: from ?? night.from,
      to: to ?? night.to,
      active: night.active,
    );
    emit(withDisplays);
    return null;
  }

  /// Whether the polkit agent is registered (`Authentication1.Registered`).
  bool agentRegistered = true;
  final StreamController<bool> _agent = StreamController<bool>.broadcast();

  void emitAgent(bool registered) {
    agentRegistered = registered;
    _agent.add(registered);
  }

  @override
  Stream<bool> get authenticationRegistered async* {
    yield agentRegistered;
    yield* _agent.stream;
  }

  /// The `alert-*` sounds of the sound service.
  List<String> alerts = const [];

  @override
  Future<List<String>> alertSounds() async => alerts;

  @override
  Future<void> playAlert(String name) async => calls.add('playAlert $name');

  /// Null: no sound service.
  bool? uiSounds;

  @override
  Future<bool?> uiSoundsEnabled() async => uiSounds;

  @override
  Future<void> setUiSoundsEnabled(bool enabled) async {
    calls.add('setUiSoundsEnabled $enabled');
    uiSounds = enabled;
  }
}

/// The system tools in memory: every change is logged in [calls] and applied to the state the
/// next read returns; [fail] makes the named call fail with that error.
class FakeTools implements SystemTools {
  final List<String> calls = [];
  final Map<String, ToolError> fail = {};

  List<AccessPoint> points = const [];
  List<NetworkDevice> devices = const [];
  Map<String, DeviceDetails> details = const {};
  List<SavedConnection> connections = const [];
  AudioDevices audio = const AudioDevices();
  ClockState clockState = const ClockState();
  List<String> zones = const [
    'Europe/Rome',
    'Europe/London',
    'America/New_York',
  ];
  String name = 'Ada’s Silica';
  LocaleState localeState = const LocaleState(language: 'en_GB.UTF-8');
  List<String> localeList = const ['en_GB.UTF-8', 'en_US.UTF-8', 'it_IT.UTF-8'];
  List<String> layouts = const ['us', 'it', 'de'];
  Map<String, List<String>> layoutVariants = const {
    'de': ['nodeadkeys'],
  };
  Map<String, String> layoutNames = const {
    'us': 'English (US)',
    'it': 'Italian',
    'de': 'German',
    'de(nodeadkeys)': 'German (no dead keys)',
  };
  List<BluetoothPeer> peers = const [];
  PowerState powerState = const PowerState();
  List<AppEntry> browserList = const [];
  String browser = '';
  List<DisplayOutput> outputs = const [];
  List<UserAccount> accounts = const [];
  List<NotifyingApp> apps = const [];

  Future<ToolError?> _log(String call) async {
    calls.add(call);
    return fail[call.split(' ').first];
  }

  @override
  Future<List<AccessPoint>> accessPoints({bool rescan = false}) async {
    if (rescan) calls.add('rescan');
    return points;
  }

  @override
  Future<List<NetworkDevice>> networkDevices() async => devices;

  @override
  Future<DeviceDetails> deviceDetails(String device) async =>
      details[device] ?? const DeviceDetails();

  @override
  Future<List<SavedConnection>> savedConnections() async => connections;

  /// Wake on LAN of the saved Ethernet connections; null: there are none.
  bool? wol;

  @override
  Future<bool?> wakeOnLan() async => wol;

  @override
  Future<ToolError?> setWakeOnLan(bool enabled) {
    wol = enabled;
    return _log('wol $enabled');
  }

  @override
  Future<ToolError?> joinWifi(String ssid, {String? password}) =>
      _log('joinWifi $ssid ${password ?? '-'}');

  @override
  Future<ToolError?> disconnect(String device) => _log('disconnect $device');

  @override
  Future<ToolError?> forgetConnection(String name) => _log('forget $name');

  @override
  Future<ToolError?> setAutoconnect(String name, bool enabled) =>
      _log('autoconnect $name $enabled');

  @override
  Future<ToolError?> setConnectionActive(String name, bool active) =>
      _log('connection $name $active');

  @override
  Future<AudioDevices> audioDevices() async => audio;

  @override
  Future<ToolError?> setDefaultAudio(int id) => _log('defaultAudio $id');

  @override
  Future<ToolError?> setAudioVolume(int id, double volume) =>
      _log('audioVolume $id ${volume.toStringAsFixed(2)}');

  @override
  Future<ToolError?> setAudioMuted(int id, bool muted) =>
      _log('audioMuted $id $muted');

  @override
  Future<ClockState> clock() async => clockState;

  @override
  Future<List<String>> timezones() async => zones;

  @override
  Future<ToolError?> setTimezone(String zone) async {
    final error = await _log('timezone $zone');
    if (error == null) {
      clockState = ClockState(
        timezone: zone,
        ntp: clockState.ntp,
        canNtp: clockState.canNtp,
      );
    }
    return error;
  }

  @override
  Future<ToolError?> setNtp(bool enabled) => _log('ntp $enabled');

  @override
  Future<String> computerName() async => name;

  @override
  Future<ToolError?> setComputerName(String name) async {
    final error = await _log('computerName $name');
    if (error == null) this.name = name;
    return error;
  }

  @override
  Future<LocaleState> locale() async => localeState;

  @override
  Future<List<String>> locales() async => localeList;

  @override
  Future<ToolError?> setLocale({
    required String language,
    String formats = '',
  }) async {
    final error = await _log('locale $language $formats');
    if (error == null) {
      localeState = LocaleState(language: language, formats: formats);
    }
    return error;
  }

  @override
  Future<List<String>> keymapLayouts() async => layouts;

  @override
  Future<List<String>> keymapVariants(String layout) async =>
      layoutVariants[layout] ?? const [];

  @override
  Future<Map<String, String>> keymapNames() async => layoutNames;

  @override
  Future<List<BluetoothPeer>> bluetoothPeers() async => peers;

  @override
  Future<ToolError?> setBluetoothDiscovery(bool discovering) =>
      _log('discovery $discovering');

  @override
  Future<ToolError?> pairBluetooth(String path) => _log('pair $path');

  @override
  Future<ToolError?> connectBluetooth(String path, bool connect) =>
      _log('btConnect $path $connect');

  @override
  Future<ToolError?> forgetBluetooth(String path) => _log('btForget $path');

  @override
  Future<PowerState> power() async => powerState;

  @override
  Future<ToolError?> setPowerProfile(PowerProfile profile) =>
      _log('profile ${profile.name}');

  @override
  Future<List<AppEntry>> browsers() async => browserList;

  @override
  Future<String> defaultBrowser() async => browser;

  @override
  Future<ToolError?> setDefaultBrowser(String id) async {
    final error = await _log('browser $id');
    if (error == null) browser = id;
    return error;
  }

  @override
  Future<List<DisplayOutput>> displays() async => outputs;

  @override
  Future<List<UserAccount>> users() async => accounts;

  @override
  Future<List<NotifyingApp>> notifyingApps() async => apps;
}

/// A machine folder with os-release, cpuinfo, meminfo, hostname and passwd.
Directory fakeRoot() {
  final root = Directory.systemTemp.createTempSync('settings-root');
  void file(String path, String text) {
    final f = File('${root.path}$path');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(text);
  }

  file(
    '/etc/os-release',
    'NAME="Silica"\nVERSION="0.1.0 (alpha)"\nPRETTY_NAME="Silica 0.1.0 (alpha)"\nID=silica\n',
  );
  file('/etc/hostname', 'silica\n');
  file(
    '/etc/passwd',
    'root:x:0:0:root:/root:/bin/bash\nada:x:1000:1000:Ada Lovelace,,,:/home/ada:/bin/bash\n',
  );
  file(
    '/proc/cpuinfo',
    'processor\t: 0\nmodel name\t: Test CPU 3000\n\nprocessor\t: 1\nmodel name\t: Test CPU 3000\n',
  );
  file('/proc/meminfo', 'MemTotal:       16000000 kB\n');
  file('/proc/sys/kernel/osrelease', '6.99.0-test\n');
  return root;
}

class Harness {
  Harness({
    required this.system,
    required this.config,
    required this.navigation,
    required this.tools,
    required this.services,
    required this.settings,
  });
  final FakeSystem system;
  final ConfigStore config;

  /// The system Settings service, in memory: what the shell would read.
  final MemorySettingsBackend settings;
  final Navigation navigation;
  final FakeTools tools;
  final Services services;
}

Future<Harness> pumpSettings(
  WidgetTester tester, {
  FakeSystem? system,
  PaneId pane = PaneId.appearance,
  Locale locale = const Locale('en'),
  Directory? root,
  CommandRunner? run,
  double height = 780,
  FakeTools? tools,
  Map<String, String> extraEnv = const {},
}) async {
  tester.view.physicalSize = Size(832, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final machine = root ?? fakeRoot();
  final home = Directory.systemTemp.createTempSync('settings-home');
  final env = {
    'HOME': home.path,
    'USER': 'ada',
    'XDG_DATA_DIRS': '${home.path}/none',
    'LANG': 'en_GB.UTF-8',
    ...extraEnv,
  };
  final fake = system ?? FakeSystem();
  final config = ConfigStore('${home.path}/.config/silica');
  final backend = MemorySettingsBackend();
  final navigation = Navigation(initial: Location(pane));
  final fakeTools = tools ?? FakeTools();
  final services = Services(
    system: fake,
    config: config,
    host: HostReader(
      root: machine.path,
      env: env,
      run: run ?? (executable, arguments) async => null,
    ),
    env: env,
    tools: fakeTools,
    settings: SilicaSettings(backend: backend),
  );
  await tester.pumpWidget(
    SettingsApp(locale: locale, navigation: navigation, services: services),
  );
  await tester.pump();
  return Harness(
    system: fake,
    config: config,
    navigation: navigation,
    tools: fakeTools,
    services: services,
    settings: backend,
  );
}
