// Battery and Energy against fake UPower and power profiles.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Battery and Energy', () {
    final profiles = FakeTools()
      ..powerState = const PowerState(
        profiles: [
          PowerProfile.powerSaver,
          PowerProfile.balanced,
          PowerProfile.performance,
        ],
        active: PowerProfile.balanced,
        secondsToEmpty: 12000,
        capacity: 91,
      );

    testWidgets('Energy: wake for network access goes through NetworkManager', (
      tester,
    ) async {
      final tools = FakeTools()
        ..powerState = profiles.powerState
        ..wol = false;
      await pumpSettings(tester, pane: PaneId.energy, tools: tools);
      await settle(tester);
      await tester.tap(switchIn('wake for network'));
      await settle(tester);
      expect(tools.calls, contains('wol true'));
      expect(tools.wol, isTrue);
    });

    testWidgets('Energy: without a wired connection the switch is disabled', (
      tester,
    ) async {
      final tools = FakeTools()..powerState = profiles.powerState;
      await pumpSettings(tester, pane: PaneId.energy, tools: tools);
      await settle(tester);
      expect(find.byKey(const ValueKey('wake for network')), findsNothing);
      expect(find.text('There is no saved wired connection.'), findsOneWidget);
    });

    testWidgets('Battery: level, time left, health, low power mode', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        tools: profiles,
        system: FakeSystem(
          const SystemState(
            reachable: true,
            batteryPresent: true,
            batteryPercent: 64,
          ),
        ),
      );
      h.navigation.openPane(PaneId.battery);
      await settle(tester);
      expect(find.text('64 %'), findsOneWidget);
      expect(find.text('On battery · 3 h 20 min left'), findsOneWidget);
      expect(find.text('91 %'), findsOneWidget);
      await tester.tap(switchIn('low power mode'));
      await settle(tester);
      expect(h.tools.calls, contains('profile powerSaver'));
    });

    testWidgets('Energy: the power mode', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.energy,
        tools: profiles,
      );
      await settle(tester);
      await choose(tester, 'power mode', 'High performance');
      await settle(tester);
      expect(h.tools.calls, contains('profile performance'));
    });

    testWidgets('Energy without power profiles says why (#68)', (tester) async {
      await pumpSettings(tester, pane: PaneId.energy);
      await settle(tester);
      expect(find.byKey(const ValueKey('power mode')), findsNothing);
      expect(find.textContaining('power-profiles-daemon'), findsWidgets);
    });

    testWidgets('Energy: display off, sleep and prevent sleep (#68)', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.energy, height: 900);
      await settle(tester);
      expect(find.text('Never'), findsNWidgets(2));
      await choose(tester, 'display off', '10 minutes');
      await tester.pump(const Duration(seconds: 1));
      await choose(tester, 'sleep after', '2 hours');
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(switchIn('prevent sleep'));
      await tester.pump();
      expect(h.config.read('power'), {
        'displayOffMinutes': 10,
        'sleepMinutes': 120,
        'preventSleep': true,
      });
      // Never is 0, which Ossido reads as no limit; the other keys stay.
      await choose(tester, 'sleep after', 'Never');
      await tester.pump(const Duration(seconds: 1));
      expect(h.config.read('power'), {
        'displayOffMinutes': 10,
        'sleepMinutes': 0,
        'preventSleep': true,
      });
      await tester.tap(switchIn('prevent sleep'));
      await tester.pump();
      expect(h.config.flag('power', 'preventSleep', fallback: true), isFalse);
    });

    testWidgets(
      'Energy shows the saved times and when the computer is held awake',
      (tester) async {
        final system = FakeSystem(const SystemState(reachable: true));
        final h = await pumpSettings(
          tester,
          pane: PaneId.energy,
          system: system,
          height: 900,
        );
        h.config.replace('power', {
          'displayOffMinutes': 45,
          'sleepMinutes': 30,
          'preventSleep': true,
        });
        system.emit(
          const SystemState(
            reachable: true,
            preventSleep: true,
            inhibited: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('45 minutes'), findsOneWidget);
        expect(find.text('30 minutes'), findsOneWidget);
        expect(
          find.text('The computer is being kept awake now.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Battery has the same sleep settings', (tester) async {
      final h = await pumpSettings(
        tester,
        tools: profiles,
        height: 900,
        system: FakeSystem(
          const SystemState(reachable: true, batteryPresent: true),
        ),
      );
      h.navigation.openPane(PaneId.battery);
      await settle(tester);
      await choose(tester, 'display off', '5 minutes');
      expect(h.config.read('power')['displayOffMinutes'], 5);
    });

    testWidgets('Lock Screen turns the display off through power.json (#68)', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.lockScreen);
      await choose(tester, 'lock display off', '30 minutes');
      expect(h.config.read('power'), {'displayOffMinutes': 30});
      expect(h.config.read('lockscreen'), isEmpty);
      expect(h.settings.values, isEmpty);
    });
  });
}
