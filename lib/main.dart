// Settings, the system settings app of Silica.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'src/app_info.dart';
import 'src/app.dart';
import 'src/model/navigation.dart';
import 'src/model/panes.dart';
import 'src/services.dart';
import 'src/session.dart';
import 'src/startup.dart';
import 'src/style.dart';
import 'src/system/config.dart';
import 'src/system/host.dart';
import 'src/system/system.dart';

void main(List<String> args) {
  startupBegin();
  WidgetsFlutterBinding.ensureInitialized();
  // About Settings and the standard app menu (silica-ui#99).
  SilicaApp.info = appInfo;
  // The toolbar is unified with the window: Ossido draws only the window buttons.
  SilicaWindow.setFullSizeContent(toolbarHeight).ignore();
  // A single-window app: it quits with its window and comes back in the same place
  // (APP-LC; Ossido remembers where the window was).
  SilicaApp.quitWhenLastWindowCloses = true;
  // 832 wide, fixed; the height is free (ST-NAV-01).
  SilicaWindow.setSizeLimits(
    min: const Size(SettingsMetrics.windowWidth, SettingsMetrics.minHeight),
    max: const Size(SettingsMetrics.windowWidth, 100000),
  ).ignore();
  final env = Platform.environment;
  final config = ConfigStore.forUser(env);
  // Nothing else is read before the first frame: the machine information comes after it and
  // every pane loads its own data when it opens.
  final navigation = Navigation(initial: Location(initialPane(args, config)));
  rememberPane(navigation, config);
  final services = Services(
    system: DaemonBackend(),
    config: config,
    host: HostReader(env: env),
    env: env,
  );
  startupMark('runApp');
  runApp(SettingsApp(services: services, navigation: navigation));
}
