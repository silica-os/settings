// Sound, Notifications and Focus against the fake daemon and PipeWire.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/panes/attention.dart';
import 'package:silica_settings/src/system/settings_files.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Sound', () {
    FakeTools audioTools() => FakeTools()
      ..audio = const AudioDevices(
        outputs: [
          AudioDevice(id: 50, name: 'Speakers', isDefault: true, volume: 0.5),
          AudioDevice(
            id: 51,
            name: 'HDMI / DisplayPort Output',
            isDefault: false,
            volume: 1,
          ),
        ],
        inputs: [
          AudioDevice(
            id: 52,
            name: 'USB Microphone',
            isDefault: true,
            volume: 0.7,
          ),
        ],
      );

    testWidgets('outputs, volume and mute', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.sound,
        tools: audioTools(),
        system: FakeSystem(
          const SystemState(
            reachable: true,
            audioAvailable: true,
            volume: 0.5,
            audioName: 'Speakers',
          ),
        ),
      );
      await settle(tester);
      expect(find.text('Speakers'), findsOneWidget);
      expect(find.text('Built-in'), findsOneWidget);
      expect(find.text('HDMI'), findsOneWidget);
      await tapKey(tester, 'audio 51');
      await settle(tester);
      expect(h.tools.calls, contains('defaultAudio 51'));
      await dragSlider(
        tester,
        find.byKey(const ValueKey('output volume')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(h.system.calls, contains('setVolume'));
      await tapKey(tester, 'mute');
      expect(h.system.calls, contains('setMuted true'));
    });

    testWidgets(
      'without the daemon\'s audio the default output goes through wpctl',
      (tester) async {
        final h = await pumpSettings(
          tester,
          pane: PaneId.sound,
          tools: audioTools(),
        );
        await settle(tester);
        await dragSlider(
          tester,
          find.byKey(const ValueKey('output volume')),
          const Offset(40, 0),
        );
        await settle(tester);
        expect(
          h.tools.calls.where((c) => c.startsWith('audioVolume 50')),
          isNotEmpty,
        );
        expect(h.system.calls, isEmpty);
        await tapKey(tester, 'mute');
        await settle(tester);
        expect(h.tools.calls, contains('audioMuted 50 true'));
      },
    );

    testWidgets('the input tab: devices and their volume', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.sound,
        tools: audioTools(),
      );
      await settle(tester);
      await tester.tap(find.text('Input'));
      await settle(tester);
      expect(find.text('USB Microphone'), findsOneWidget);
      expect(find.text('USB'), findsOneWidget);
      await dragSlider(
        tester,
        find.byKey(const ValueKey('input volume')),
        const Offset(-40, 0),
      );
      await settle(tester);
      expect(
        h.tools.calls.where((c) => c.startsWith('audioVolume 52')),
        isNotEmpty,
      );
      await tapKey(tester, 'input mute');
      await settle(tester);
      expect(h.tools.calls, contains('audioMuted 52 true'));
    });

    testWidgets('interface sounds follow the sound service', (tester) async {
      final system = FakeSystem()..uiSounds = true;
      final h = await pumpSettings(tester, pane: PaneId.sound, system: system);
      await settle(tester);
      await tester.tap(switchIn('ui sounds'));
      await settle(tester);
      expect(h.system.calls, contains('setUiSoundsEnabled false'));
      expect(system.uiSounds, isFalse);
    });

    testWidgets('without the sound service the effects wait (#64)', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.sound);
      await settle(tester);
      expect(find.byKey(const ValueKey('ui sounds')), findsNothing);
      expect(
        find.textContaining('sound service isn’t running'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AmalfiPushButton>(find.byKey(const ValueKey('play alert')))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<AmalfiSwitch>(switchIn('volume feedback')).onChanged,
        isNull,
      );
      expect(
        tester
            .widget<AmalfiSlider>(
              find.descendant(
                of: find.byKey(const ValueKey('alert volume')),
                matching: find.byType(AmalfiSlider),
              ),
            )
            .onChanged,
        isNull,
      );
      expect(h.config.read('sound'), isEmpty);
      expect(h.system.calls, isEmpty);
    });

    testWidgets('alert sound, alert volume and volume feedback (#64)', (
      tester,
    ) async {
      final system = FakeSystem()
        ..uiSounds = true
        ..alerts = const ['alert-crystal', 'alert-woodblock'];
      final h = await pumpSettings(
        tester,
        pane: PaneId.sound,
        system: system,
        height: 1000,
      );
      await settle(tester);
      expect(find.text('Crystal'), findsOneWidget);
      // Choosing a sound saves it and plays it.
      await choose(tester, 'alert sound', 'Woodblock');
      expect(h.config.text('sound', 'alert', fallback: ''), 'alert-woodblock');
      expect(system.calls, ['playAlert alert-woodblock']);
      await tapKey(tester, 'play alert');
      expect(system.calls.last, 'playAlert alert-woodblock');
      // The volume is saved and the alert plays at it once the slider is let go.
      system.calls.clear();
      await dragSlider(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('alert volume')),
          matching: find.byType(AmalfiSlider),
        ),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('sound')['alertVolume'], 0);
      expect(system.calls, ['playAlert ']);
      await tester.tap(switchIn('volume feedback'));
      await tester.pump();
      expect(h.config.read('sound'), {
        'alert': 'alert-woodblock',
        'alertVolume': 0,
        'volumeFeedback': true,
      });
    });

    testWidgets('alertLabel makes a readable name', (_) async {
      expect(alertLabel('alert-crystal'), 'Crystal');
      expect(alertLabel('alert-soft-bell'), 'Soft bell');
      expect(alertLabel('bell'), 'Bell');
    });
  });

  testWidgets('Notifications: the apps and their banner style', (tester) async {
    final tools = FakeTools()
      ..apps = const [
        NotifyingApp(key: 'org.gnome.Nautilus', name: 'Files'),
        NotifyingApp(key: 'firefox', name: 'Firefox'),
      ];
    final h = await pumpSettings(
      tester,
      pane: PaneId.notifications,
      tools: tools,
      height: 1000,
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('app firefox')), findsOneWidget);
    await tapKey(tester, 'app org.gnome.Nautilus');
    expect(h.navigation.location.sub, SubPaneId.notificationApp);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('title'))).data,
      'Files',
    );
    await tester.tap(find.text('Stay until dismissed'));
    await tester.pump();
    Object? style() =>
        h.settings.values['notifications.apps.org.gnome.Nautilus.style'];
    expect(style(), 'alerts');
    await tester.tap(switchIn('allow notifications'));
    await tester.pump();
    expect(style(), 'none');
    await tester.tap(switchIn('allow notifications'));
    await tester.pump();
    expect(style(), 'alerts');
  });

  testWidgets('Notifications: previews, Notification Center and grouping', (
    tester,
  ) async {
    final tools = FakeTools()
      ..apps = const [NotifyingApp(key: 'firefox', name: 'Firefox')];
    final h = await pumpSettings(
      tester,
      pane: PaneId.notifications,
      tools: tools,
      height: 1000,
    );
    await settle(tester);
    await choose(tester, 'previews', 'Never');
    expect(h.settings.values['notifications.previews'], 'never');
    await tapKey(tester, 'app firefox');
    Map<String, Object?> app() => {
      for (final e in h.settings.values.entries)
        if (e.key.startsWith('notifications.apps.firefox.'))
          e.key.substring('notifications.apps.firefox.'.length): e.value,
    };
    await tester.tap(switchIn('show in center'));
    await tester.pump();
    expect(app()['showInCenter'], false);
    await tester.tap(switchIn('app sound'));
    await tester.pump();
    expect(app()['sound'], false);
    await tester.tap(switchIn('app sound'));
    await tester.pump();
    expect(app().containsKey('sound'), isFalse);
    await choose(tester, 'app previews', 'Always');
    expect(app()['previews'], 'always');
    await choose(tester, 'app grouping', 'Off');
    expect(app()['grouping'], 'off');
    // Back to the defaults: the keys go away.
    await tester.tap(switchIn('show in center'));
    await tester.pump();
    await choose(tester, 'app previews', 'Default');
    await choose(tester, 'app grouping', 'Automatic');
    expect(app().containsKey('showInCenter'), isFalse);
    expect(app().containsKey('previews'), isFalse);
    expect(app().containsKey('grouping'), isFalse);
  });

  testWidgets('Focus: Do Not Disturb goes through the daemon', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.focus);
    await tester.tap(switchIn('dnd switch'));
    await tester.pump();
    expect(h.system.calls, ['setDoNotDisturb true']);
  });

  group('Focus modes (#72)', () {
    const reachable = SystemState(reachable: true);
    FakeTools appTools() => FakeTools()
      ..apps = const [
        NotifyingApp(key: 'org.gnome.Nautilus', name: 'Files'),
        NotifyingApp(key: 'firefox', name: 'Firefox'),
      ];
    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );
    Future<void> done(WidgetTester tester) async {
      await tapKey(tester, 'focus done');
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
    }

    testWidgets('add a mode with a name, a symbol, apps and people', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.focus,
        tools: appTools(),
        height: 1000,
      );
      await settle(tester);
      expect(find.textContaining('No Focus modes yet'), findsOneWidget);
      await tapKey(tester, 'add focus');
      await settle(tester);
      // Done waits for a name.
      expect(
        tester
            .widget<AmalfiPushButton>(find.byKey(const ValueKey('focus done')))
            .onPressed,
        isNull,
      );
      await tester.enterText(field('focus name'), 'Deep work');
      await tester.pump();
      await tapKey(tester, 'focus symbol lightbulb');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('focus app firefox')),
          matching: find.byType(AmalfiCheckbox),
        ),
      );
      await tester.pump();
      await tester.enterText(field('focus person'), 'Ada');
      await tapKey(tester, 'add person');
      // A name left in the field when Done is pressed counts too.
      await tester.enterText(field('focus person'), 'Grace');
      await tester.pump();
      await done(tester);
      expect(h.config.read('focus'), {
        'modes': [
          {
            'id': 'deep-work',
            'name': 'Deep work',
            'symbol': 'lightbulb',
            'allowedApps': ['firefox'],
            'allowedPeople': ['Ada', 'Grace'],
          },
        ],
      });
      expect(find.text('Deep work'), findsOneWidget);
      expect(find.text('1 app, 2 people'), findsOneWidget);
      expect(h.system.calls, isEmpty);
    });

    testWidgets('the switch turns a mode on and off through SetFocus', (
      tester,
    ) async {
      final system = FakeSystem(reachable);
      final h = await pumpSettings(
        tester,
        pane: PaneId.focus,
        system: system,
        height: 1000,
      );
      h.config.writeFocusModes(const [FocusMode(id: 'work', name: 'Work')]);
      system.emit(reachable);
      await tester.pump();
      await tester.pump();
      await tester.tap(switchIn('focus mode work'));
      await tester.pump();
      expect(system.calls, ['setFocus work']);
      system.emit(const SystemState(reachable: true, focus: 'work'));
      await tester.pump();
      await tester.pump();
      expect(find.text('On'), findsWidgets);
      await tester.tap(switchIn('focus mode work'));
      await tester.pump();
      expect(system.calls.last, 'setFocus ');
    });

    testWidgets('edit the active mode: saved, and the daemon is told again', (
      tester,
    ) async {
      final system = FakeSystem(
        const SystemState(reachable: true, focus: 'work'),
      );
      final h = await pumpSettings(
        tester,
        pane: PaneId.focus,
        system: system,
        tools: appTools(),
        height: 1000,
      );
      h.config.replace('focus', {
        'active': 'work',
        'modes': [
          {
            'id': 'work',
            'name': 'Work',
            'symbol': 'person',
            'allowedApps': ['firefox'],
            'allowedPeople': ['Ada'],
          },
        ],
      });
      system.emit(const SystemState(reachable: true, focus: 'work'));
      await tester.pump();
      await tester.pump();
      await tapRowButton(tester, 'focus mode work');
      await settle(tester);
      await tester.enterText(field('focus name'), 'Office');
      await tester.pump();
      await tapKey(tester, 'remove person Ada');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('focus app firefox')),
          matching: find.byType(AmalfiCheckbox),
        ),
      );
      await tester.pump();
      await done(tester);
      expect(h.config.read('focus'), {
        'active': 'work',
        'modes': [
          {
            'id': 'work',
            'name': 'Office',
            'symbol': 'person',
            'allowedApps': <String>[],
            'allowedPeople': <String>[],
          },
        ],
      });
      expect(system.calls, ['setFocus work']);
    });

    testWidgets('delete the active mode: Focus goes off first', (tester) async {
      final system = FakeSystem(
        const SystemState(reachable: true, focus: 'work'),
      );
      final h = await pumpSettings(
        tester,
        pane: PaneId.focus,
        system: system,
        height: 1000,
      );
      h.config.writeFocusModes(const [
        FocusMode(id: 'work', name: 'Work'),
        FocusMode(id: 'sleep', name: 'Sleep'),
      ]);
      system.emit(const SystemState(reachable: true, focus: 'work'));
      await tester.pump();
      await tester.pump();
      await tapRowButton(tester, 'focus mode work');
      await settle(tester);
      await tapKey(tester, 'delete focus');
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(system.calls, ['setFocus ']);
      final modes = h.config.read('focus')['modes'] as List;
      expect([for (final m in modes) (m as Map)['id']], ['sleep']);
      expect(find.text('Work'), findsNothing);
    });

    testWidgets('cancel leaves the modes alone; Do Not Disturb stays', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.focus,
        system: FakeSystem(reachable),
        height: 1000,
      );
      await tapKey(tester, 'add focus');
      await settle(tester);
      await tester.enterText(field('focus name'), 'Nope');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(h.config.read('focus'), isEmpty);
      await tester.tap(switchIn('dnd switch'));
      await tester.pump();
      expect(h.system.calls, ['setDoNotDisturb true']);
    });

    testWidgets('the note names what the shell still has to do', (
      tester,
    ) async {
      await pumpSettings(tester, pane: PaneId.focus, height: 1000);
      expect(find.textContaining('needs the shell.'), findsOneWidget);
    });
  });
}
