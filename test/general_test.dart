// General and its sub-panes against the fake machine and systemd tools.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('General', () {
    testWidgets(
      'the toolbar names the pane over the header card (kit General)',
      (tester) async {
        await pumpSettings(tester, pane: PaneId.general);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('title'))).data,
          'General',
        );
        await tapKey(tester, 'general about');
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('title'))).data,
          'About',
        );
      },
    );

    testWidgets('About shows the machine', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.general);
      h.navigation.openSub(SubPaneId.about);
      await tester.pump();
      expect(find.text('Silica'), findsOneWidget);
      expect(find.text('Version 0.1.0 (alpha)'), findsOneWidget);
      expect(find.text('Test CPU 3000 (2 cores)'), findsOneWidget);
      expect(find.text('16.4 GB'), findsOneWidget);
      expect(find.text('6.99.0-test'), findsOneWidget);
    });

    testWidgets('Storage measures the folders and empties the trash', (
      tester,
    ) async {
      final home = Directory.systemTemp.createTempSync('settings-trash');
      final trash = Directory('${home.path}/.local/share/Trash/files')
        ..createSync(recursive: true);
      File('${trash.path}/old.txt').writeAsStringSync('x');
      final h = await pumpSettings(
        tester,
        pane: PaneId.general,
        extraEnv: {'XDG_DATA_HOME': '${home.path}/.local/share'},
        run: (exe, args) async => switch (exe) {
          'df' => '     Size    Avail\n500000000000 200000000000\n',
          'du' => '${args.last.endsWith('Trash/files') ? 2000 : 1000000}\t.\n',
          _ => null,
        },
      );
      h.navigation.openSub(SubPaneId.storage);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await settle(tester);
      expect(find.text('200 GB available of 500 GB'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      await tapKey(tester, 'empty trash');
      expect(find.byKey(const ValueKey('confirm')), findsOneWidget);
      await tester.tap(find.text('Empty Trash').last);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await settle(tester);
      expect(trash.listSync(), isEmpty);
    });

    testWidgets('Sharing renames the computer; a refusal names the cause', (
      tester,
    ) async {
      final tools = FakeTools();
      final h = await pumpSettings(tester, pane: PaneId.general, tools: tools);
      h.navigation.openSub(SubPaneId.sharing);
      await settle(tester);
      expect(find.text('Ada’s Silica'), findsOneWidget);
      tools.fail['computerName'] = const ToolError(
        ToolErrorKind.authentication,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('computer name')),
          matching: find.byType(EditableText),
        ),
        'Studio',
      );
      await tester.pump();
      await tapKey(tester, 'rename computer');
      await settle(tester);
      expect(h.tools.calls, contains('computerName Studio'));
      expect(find.textContaining('administrator'), findsOneWidget);
      tools.fail.clear();
      await tapKey(tester, 'rename computer');
      await settle(tester);
      expect(find.textContaining('administrator'), findsNothing);
    });

    testWidgets(
      'Date & Time: the menu bar clock options set the menubar.clock keys',
      (tester) async {
        final h = await pumpSettings(
          tester,
          pane: PaneId.general,
          height: 1000,
        );
        h.navigation.openSub(SubPaneId.dateTime);
        await settle(tester);
        Map<String, Object?> clock() => {
          for (final e in h.settings.values.entries)
            if (e.key.startsWith('menubar.clock.'))
              e.key.substring('menubar.clock.'.length): e.value,
        };
        await tester.tap(switchIn('clock 24 hour'));
        await tester.pump();
        expect(clock()['hour24'], false);
        await tester.tap(switchIn('clock seconds'));
        await tester.pump();
        await tester.tap(switchIn('clock weekday'));
        await tester.pump();
        await choose(tester, 'clock date', 'Never');
        expect(clock(), {
          'hour24': false,
          'seconds': true,
          'weekday': false,
          'date': 'never',
        });
      },
    );

    testWidgets('Date & Time: automatic time and the time zone', (
      tester,
    ) async {
      final tools = FakeTools()
        ..clockState = const ClockState(
          timezone: 'Europe/London',
          ntp: true,
          canNtp: true,
        );
      final h = await pumpSettings(tester, pane: PaneId.general, tools: tools);
      h.navigation.openSub(SubPaneId.dateTime);
      await settle(tester);
      await tester.tap(switchIn('automatic time'));
      await settle(tester);
      expect(h.tools.calls, contains('ntp false'));
      await tapKey(tester, 'change time zone');
      await settle(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('choice search')),
          matching: find.byType(EditableText),
        ),
        'rome',
      );
      await tester.pump();
      await tapKey(tester, 'choice Europe/Rome');
      await tapKey(tester, 'choice done');
      await settle(tester);
      expect(h.tools.calls, contains('timezone Europe/Rome'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Europe/Rome'), findsOneWidget);
    });

    testWidgets('Language & Region: the system language and formats', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.general);
      h.navigation.openSub(SubPaneId.languageRegion);
      await settle(tester);
      expect(find.text('en_GB'), findsWidgets);
      await tapKey(tester, 'change language');
      await settle(tester);
      await tapKey(tester, 'choice it_IT.UTF-8');
      await tapKey(tester, 'choice done');
      await settle(tester);
      expect(h.tools.calls, contains('locale it_IT.UTF-8 '));
      await tester.pump(const Duration(seconds: 1));
      await tapKey(tester, 'change region');
      await settle(tester);
      await tapKey(tester, 'choice en_US.UTF-8');
      await tapKey(tester, 'choice done');
      await settle(tester);
      expect(h.tools.calls, contains('locale it_IT.UTF-8 en_US.UTF-8'));
    });

    group('without the polkit agent (#69)', () {
      bool enabled(WidgetTester tester, String key) =>
          tester
              .widget<AmalfiPushButton>(find.byKey(ValueKey(key)))
              .onPressed !=
          null;

      testWidgets('time zone and automatic time wait for the agent', (
        tester,
      ) async {
        final system = FakeSystem()..agentRegistered = false;
        final tools = FakeTools()
          ..clockState = const ClockState(ntp: true, canNtp: true);
        final h = await pumpSettings(
          tester,
          pane: PaneId.general,
          system: system,
          tools: tools,
        );
        h.navigation.openSub(SubPaneId.dateTime);
        await settle(tester);
        expect(enabled(tester, 'change time zone'), isFalse);
        expect(
          tester.widget<AmalfiSwitch>(switchIn('automatic time')).onChanged,
          isNull,
        );
        expect(find.textContaining('administrator'), findsWidgets);
        system.emitAgent(true);
        await settle(tester);
        expect(enabled(tester, 'change time zone'), isTrue);
        expect(
          tester.widget<AmalfiSwitch>(switchIn('automatic time')).onChanged,
          isNotNull,
        );
        expect(find.textContaining('administrator'), findsNothing);
      });

      testWidgets('the computer name waits for the agent', (tester) async {
        final system = FakeSystem()..agentRegistered = false;
        final h = await pumpSettings(
          tester,
          pane: PaneId.general,
          system: system,
        );
        h.navigation.openSub(SubPaneId.sharing);
        await settle(tester);
        expect(enabled(tester, 'rename computer'), isFalse);
        expect(find.textContaining('administrator'), findsOneWidget);
        system.emitAgent(true);
        await settle(tester);
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('computer name')),
            matching: find.byType(EditableText),
          ),
          'Studio',
        );
        await tester.pump();
        expect(enabled(tester, 'rename computer'), isTrue);
        await tapKey(tester, 'rename computer');
        await settle(tester);
        expect(h.tools.calls, contains('computerName Studio'));
      });

      testWidgets('the language waits for the agent', (tester) async {
        final system = FakeSystem()..agentRegistered = false;
        final h = await pumpSettings(
          tester,
          pane: PaneId.general,
          system: system,
        );
        h.navigation.openSub(SubPaneId.languageRegion);
        await settle(tester);
        expect(enabled(tester, 'change language'), isFalse);
        expect(enabled(tester, 'change region'), isFalse);
        system.emitAgent(true);
        await settle(tester);
        expect(enabled(tester, 'change language'), isTrue);
        expect(enabled(tester, 'change region'), isTrue);
      });
    });
  });
}
