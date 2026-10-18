// Helpers of the pane tests: tapping, switches, form pop-ups, and fake network data.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';

/// Taps the widget with [key].
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the push button inside the row with [key].
Future<void> tapRowButton(WidgetTester tester, String key) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(AmalfiPushButton),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The switch of the row with [key] (or of the widget itself when it is a switch).
Finder switchIn(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(AmalfiSwitch),
  matchRoot: true,
);

/// Opens the form pop-up of the row with [key] and chooses [item].
Future<void> choose(WidgetTester tester, String key, String item) async {
  await tester.tap(
    find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byWidgetPredicate((w) => w is AmalfiPopUpButton),
          matchRoot: true,
        )
        .first,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final row = find
      .descendant(of: find.byType(AmalfiMenu), matching: find.text(item))
      .last;
  // A long menu opens with the selected row over the control and the rest scrolled (the
  // measured placement): scroll to the row as the user would.
  await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
  await tester.pump();
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  // The menu fades out over the pane for a moment.
  await tester.pump(const Duration(milliseconds: 500));
}

/// Fills the window and waits for the tools' futures.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const wifiOn = SystemState(
  reachable: true,
  wifiAvailable: true,
  wifiEnabled: true,
  wifiSsid: 'Home',
  wifiStrength: 80,
);

FakeTools networkTools() => FakeTools()
  ..points = const [
    AccessPoint(ssid: 'Home', strength: 80, security: 'WPA2', inUse: true),
    AccessPoint(ssid: 'Office', strength: 60, security: 'WPA2', inUse: false),
    AccessPoint(ssid: 'Cafe', strength: 30, security: 'WPA2', inUse: false),
    AccessPoint(ssid: 'Library', strength: 20, security: '', inUse: false),
  ]
  ..connections = const [
    SavedConnection(name: 'Home', type: '802-11-wireless', active: true),
    SavedConnection(name: 'Office', type: '802-11-wireless', active: false),
    SavedConnection(name: 'Work', type: 'wireguard', active: false),
  ]
  ..devices = const [
    NetworkDevice(
      name: 'wlp2s0',
      type: 'wifi',
      state: 'connected',
      connection: 'Home',
    ),
    NetworkDevice(
      name: 'enp3s0',
      type: 'ethernet',
      state: 'unavailable',
      connection: '',
    ),
    NetworkDevice(
      name: 'lo',
      type: 'loopback',
      state: 'connected',
      connection: 'lo',
    ),
  ]
  ..details = const {
    'wlp2s0': DeviceDetails(
      hardwareAddress: 'AA:BB:CC:DD:EE:FF',
      ipv4: ['192.168.1.20/24'],
      gateway: '192.168.1.1',
      dns: ['192.168.1.1'],
    ),
  };

/// Drags a slider the way a pointer does: from its centre in small steps (a single large
/// move only starts the pan).
Future<void> dragSlider(WidgetTester tester, Finder slider, Offset by) async {
  final gesture = await tester.startGesture(tester.getCenter(slider));
  final steps = (by.distance / 10).ceil().clamp(1, 200);
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(by / steps.toDouble());
    await tester.pump();
  }
  // The pan starts after the touch slop; the extra moves are updates.
  for (var i = 0; i < 2; i++) {
    await gesture.moveBy(by / by.distance);
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}
