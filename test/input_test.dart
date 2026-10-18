// Keyboard, Users, Printers, the panes waiting for a backend, and every pane building.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/panes/input.dart';
import 'package:silica_settings/src/system/shortcuts.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Keyboard (#73)', () {
    testWidgets('the sliders start from the session and write keyboard.json', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.keyboard,
        extraEnv: const {'OSSIDO_KEY_REPEAT': '250,30'},
      );
      AmalfiSlider slider(String key) =>
          tester.widget<AmalfiSlider>(find.byKey(ValueKey(key)));
      // 30 per second and 250 ms are the steps 6 and 5 of the sliders.
      expect(slider('repeat rate').value, 6);
      expect(slider('repeat delay').value, 5);
      expect(slider('repeat rate').onChanged, isNotNull);
      expect(h.config.read('keyboard'), isEmpty);
      await dragSlider(
        tester,
        find.byKey(const ValueKey('repeat rate')),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard')['repeatRate'], 0);
      await dragSlider(
        tester,
        find.byKey(const ValueKey('repeat delay')),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard')['repeatDelay'], 1500);
      expect(slider('repeat delay').value, 0);
      // The other keys of the file are kept.
      h.config.write('keyboard', 'options', 'caps:escape');
      await dragSlider(
        tester,
        find.byKey(const ValueKey('repeat rate')),
        const Offset(400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard'), {
        'repeatRate': 40,
        'repeatDelay': 1500,
        'options': 'caps:escape',
      });
    });

    testWidgets('keyboard navigation goes to theme.json and the daemon', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.keyboard, height: 1000);
      await tester.tap(switchIn('keyboard navigation'));
      await tester.pump();
      expect(h.config.read('theme')['keyboardNavigation'], true);
      expect(h.system.calls.last, 'setLook {keyboardNavigation: true}');
      expect(SilicaSystemLook.current.keyboardNavigation, isTrue);
    });

    testWidgets('input sources: add a layout and a variant, remove, at most 4', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.keyboard,
        tools: FakeTools()..layouts = const ['us', 'it', 'de', 'fr'],
      );
      await settle(tester);
      expect(find.text('System default'), findsOneWidget);
      await tapRowButton(tester, 'input sources');
      expect(find.byKey(const ValueKey('source default')), findsOneWidget);
      // Chooses [layout] (and [variant] when it has some) in the pop-up sheets.
      Future<void> add(String layout, [String? variant]) async {
        await tapKey(tester, 'add source');
        await settle(tester);
        await tapKey(tester, 'choice $layout');
        await tapKey(tester, 'choice done');
        await tester.pump(const Duration(seconds: 1));
        await settle(tester);
        if (variant != null) {
          await tapKey(tester, 'choice $variant');
          await tapKey(tester, 'choice done');
          await tester.pump(const Duration(seconds: 1));
          await settle(tester);
        }
      }

      await add('it');
      expect(h.config.read('keyboard')['layouts'], ['it']);
      await add('de', 'nodeadkeys');
      expect(h.config.read('keyboard')['layouts'], ['it', 'de(nodeadkeys)']);
      expect(find.text('German (no dead keys)'), findsOneWidget);
      await tapKey(tester, 'remove source it');
      expect(h.config.read('keyboard')['layouts'], ['de(nodeadkeys)']);
      // Four is the most: the fourth source disables Add.
      await add('us');
      await add('fr');
      await add('it');
      expect(h.config.read('keyboard')['layouts'], [
        'de(nodeadkeys)',
        'us',
        'fr',
        'it',
      ]);
      expect(
        tester
            .widget<AmalfiPushButton>(find.byKey(const ValueKey('add source')))
            .onPressed,
        isNull,
      );
      for (final id in ['de(nodeadkeys)', 'us', 'fr', 'it']) {
        await tapKey(tester, 'remove source $id');
      }
      expect(h.config.read('keyboard').containsKey('layouts'), isFalse);
    });
  });

  testWidgets('Keyboard: the shortcuts sheet lists Silica bindings', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.keyboard);
    await tapKey(tester, 'shortcuts');
    expect(find.text('Logo ⇧ 3'), findsOneWidget);
    await tapKey(tester, 'shortcut category 2');
    expect(find.text('Logo Space'), findsOneWidget);
  });

  group('Keyboard shortcuts (#20)', () {
    testWidgets('a shortcut is switched off and back to its default', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.keyboard);
      await tapKey(tester, 'shortcuts');
      await tapKey(tester, 'shortcut category 3');
      await tapKey(tester, 'shortcut on window.minimize');
      expect(h.config.read('shortcuts'), {'window.minimize': null});
      expect(find.text('None'), findsWidgets);
      await tapKey(tester, 'shortcut on window.minimize');
      expect(
        h.config.read('shortcuts').containsKey('window.minimize'),
        isFalse,
      );
    });

    testWidgets('new keys are recorded while Ossido lets them through', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.keyboard);
      await tapKey(tester, 'shortcuts');
      await tapKey(tester, 'shortcut category 3');
      await tapKey(tester, 'shortcut keys window.minimize');
      expect(h.config.read('shortcuts')['capture'], isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(h.config.read('shortcuts'), {'window.minimize': 'Logo+n'});
      expect(find.text('Logo N'), findsOneWidget);
    });

    testWidgets('a combination in use is refused', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.keyboard);
      await tapKey(tester, 'shortcuts');
      await tapKey(tester, 'shortcut category 3');
      await tapKey(tester, 'shortcut keys window.minimize');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(find.textContaining('Already used'), findsOneWidget);
      expect(
        h.config.read('shortcuts').containsKey('window.minimize'),
        isFalse,
      );
    });

    test('combinations read and write the catalog format', () {
      final combo = KeyCombo.parse('Logo+Ctrl+Shift+3');
      expect(combo?.text, 'Logo+Ctrl+Shift+3');
      expect(combo?.display, 'Logo ⌃ ⇧ 3');
      expect(KeyCombo.parse('Hyper+Q'), isNull);
      expect(const KeyCombo(key: 'a').isUsable, isFalse);
      expect(const KeyCombo(key: 'F5').isUsable, isTrue);
    });
  });

  group('Mouse and Trackpad (#74)', () {
    Finder sliderIn(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(AmalfiSlider),
    );
    AmalfiSlider slider(WidgetTester tester, String key) =>
        tester.widget<AmalfiSlider>(sliderIn(key));

    testWidgets('Mouse writes the mouse object of input.json', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.mouse, height: 900);
      expect(slider(tester, 'mouse speed').value, 0);
      await dragSlider(tester, sliderIn('mouse speed'), const Offset(400, 0));
      await tester.pump();
      expect(h.config.read('input'), {
        'mouse': {'speed': 1.0},
      });
      await tester.tap(switchIn('mouse natural scrolling'));
      await tester.pump();
      await choose(tester, 'mouse secondary click', 'Left button');
      await dragSlider(
        tester,
        sliderIn('mouse scroll speed'),
        const Offset(400, 0),
      );
      await tester.pump();
      expect(h.config.read('input'), {
        'mouse': {
          'speed': 1.0,
          'naturalScroll': true,
          'secondaryClick': 'left',
          'scrollSpeed': 10.0,
        },
      });
      await dragSlider(
        tester,
        sliderIn('mouse scroll speed'),
        const Offset(-800, 0),
      );
      await tester.pump();
      final input = h.config.read('input')['mouse'] as Map;
      expect(input['scrollSpeed'], 0.1);
      expect(find.textContaining('Not available yet in Silica'), findsNothing);
    });

    testWidgets('the double-click speed is a time shared with the apps', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: PaneId.mouse, height: 1000);
      final slider = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('double click speed')),
          matching: find.byType(AmalfiSlider),
        ),
      );
      // The right end is the fastest, 150 ms.
      await tester.tapAt(Offset(slider.right - 1, slider.center.dy));
      await tester.pump();
      expect(
        h.config.read('theme')['doubleClickMs'],
        inInclusiveRange(150, 170),
      );
      expect(SilicaSystemLook.current.doubleClickMs, lessThan(171));
      await tester.tapAt(Offset(slider.left + 1, slider.center.dy));
      await tester.pump();
      expect(
        h.config.read('theme')['doubleClickMs'],
        inInclusiveRange(950, 1000),
      );
    });

    testWidgets('scroll speed is logarithmic with 1x in the middle', (_) async {
      expect(scrollSliderOf(1), closeTo(0.5, 1e-9));
      expect(scrollSpeedOf(0.5), 1.0);
      expect(scrollSpeedOf(0), 0.1);
      expect(scrollSpeedOf(1), 10.0);
      expect(scrollSliderOf(0.01), closeTo(0, 1e-9));
    });

    testWidgets('the Trackpad pane is in the sidebar only with a touchpad', (
      tester,
    ) async {
      final system = FakeSystem(const SystemState(reachable: true));
      await pumpSettings(tester, system: system, height: 1300);
      expect(find.byKey(const ValueKey('pane trackpad')), findsNothing);
      system.emit(const SystemState(reachable: true, touchpad: true));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('pane trackpad')), findsOneWidget);
      system.emit(const SystemState(reachable: true));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('pane trackpad')), findsNothing);
    });

    testWidgets('a window on Trackpad falls back when there is no touchpad', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        system: FakeSystem(const SystemState(reachable: true)),
        pane: PaneId.trackpad,
        height: 1300,
      );
      await tester.pump();
      await tester.pump();
      expect(h.navigation.pane, PaneId.wifi);
    });

    testWidgets('Trackpad writes the touchpad object of input.json', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        system: FakeSystem(const SystemState(reachable: true, touchpad: true)),
        pane: PaneId.trackpad,
        height: 1000,
      );
      h.config.write('input', 'mouse', {'speed': 0.5});
      await tester.tap(switchIn('touchpad tap to click'));
      await tester.pump();
      await tester.tap(switchIn('touchpad disable while typing'));
      await tester.pump();
      await tester.tap(switchIn('touchpad natural scrolling'));
      await tester.pump();
      await choose(
        tester,
        'touchpad secondary click',
        'Click in the bottom right corner',
      );
      await dragSlider(
        tester,
        sliderIn('touchpad speed'),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('input'), {
        'mouse': {'speed': 0.5},
        'touchpad': {
          'tapToClick': true,
          'disableWhileTyping': false,
          'naturalScroll': true,
          'secondaryClick': 'bottomRight',
          'speed': -1.0,
        },
      });
    });
  });

  testWidgets('Accessibility: Reduce transparency and Reduce motion', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.accessibility);
    await tapKey(tester, 'accessibility display');
    expect(h.navigation.location.sub, SubPaneId.accessibilityDisplay);
    await tester.tap(switchIn('reduce transparency'));
    await tester.pump();
    expect(h.config.read('theme')['reduceTransparency'], true);
    expect(h.system.calls.last, 'setLook {reduceTransparency: true}');
    expect(SilicaSystemLook.current.reduceTransparency, isTrue);
    h.navigation.openPane(PaneId.accessibility);
    await tester.pump();
    await tapKey(tester, 'accessibility motion');
    expect(h.navigation.location.sub, SubPaneId.accessibilityMotion);
    await tester.tap(switchIn('reduce motion'));
    await tester.pump();
    expect(h.config.read('theme')['reduceMotion'], true);
    expect(SilicaSystemLook.current.reduceMotion, isTrue);
    await tester.tap(switchIn('reduce motion'));
    await tester.pump();
    expect(h.config.read('theme')['reduceMotion'], false);
    h.navigation.openPane(PaneId.accessibility);
    await tester.pump();
    await tapKey(tester, 'accessibility display');
    await tester.tap(switchIn('increase contrast'));
    await tester.pump();
    expect(h.config.read('theme')['increaseContrast'], true);
    expect(h.system.calls.last, 'setLook {increaseContrast: true}');
    expect(SilicaSystemLook.current.increaseContrast, isTrue);
  });

  testWidgets('Accessibility: Larger Text and the pointer size', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.accessibility);
    await tapKey(tester, 'accessibility larger text');
    expect(h.navigation.location.sub, SubPaneId.accessibilityLargerText);
    final text = tester.widget<AmalfiSlider>(
      find.descendant(
        of: find.byKey(const ValueKey('text size')),
        matching: find.byType(AmalfiSlider),
      ),
    );
    text.onChanged!(1.3);
    await tester.pump();
    expect(h.config.read('theme')['textScale'], 1.3);
    expect(h.system.calls.last, 'setLook {textScale: 1.3}');
    expect(SilicaSystemLook.current.textScale, 1.3);
    SilicaSystemLook.apply(const SystemLook());
    h.navigation.openPane(PaneId.accessibility);
    await tester.pump();
    await tapKey(tester, 'accessibility display');
    final pointer = tester.widget<AmalfiSlider>(
      find.descendant(
        of: find.byKey(const ValueKey('pointer size')),
        matching: find.byType(AmalfiSlider),
      ),
    );
    pointer.onChanged!(48.4);
    await tester.pump();
    // Ossido reads theme.json; the daemon is not involved.
    expect(h.config.read('theme')['cursorSize'], 48);
    expect(h.system.calls.last, 'setLook {textScale: 1.3}');
  });

  testWidgets('Users & Groups lists the accounts', (tester) async {
    final tools = FakeTools()
      ..accounts = const [
        UserAccount(login: 'bob', name: 'Bob', uid: 1001, admin: false),
        UserAccount(login: 'ada', name: 'Ada Lovelace', uid: 1000, admin: true),
      ];
    await pumpSettings(tester, pane: PaneId.users, tools: tools);
    await settle(tester);
    expect(find.text('ada · Admin'), findsOneWidget);
    expect(find.text('bob · Standard'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('current user'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('user bob'))).dy),
    );
  });

  testWidgets('Printers: the CUPS printers and the default one', (
    tester,
  ) async {
    final runs = <String>[];
    await pumpSettings(
      tester,
      pane: PaneId.printers,
      run: (exe, args) async {
        runs.add('$exe ${args.join(' ')}');
        return switch (exe) {
          'lpstat' =>
            'printer Office is idle.\nprinter Home is idle.\n'
                'system default destination: Office\n',
          'lpoptions' => '',
          _ => null,
        };
      },
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('printer Home')), findsOneWidget);
    await choose(tester, 'default printer', 'Home');
    await settle(tester);
    expect(runs, contains('lpoptions -d Home'));
  });

  for (final pane in [
    PaneId.screenTime,
    PaneId.lockScreen,
    PaneId.privacy,
    PaneId.password,
    PaneId.internetAccounts,
    PaneId.accessibility,
    PaneId.search,
  ]) {
    testWidgets('${pane.name}: waits for its backend and says so', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: pane, height: 1300);
      expect(find.byKey(const ValueKey('unavailable')), findsWidgets);
      expect(find.textContaining('Not available yet in Silica'), findsWidgets);
      // Nothing reaches the system from these panes.
      for (final s in find.byType(AmalfiSwitch).evaluate()) {
        await tester.tap(find.byWidget(s.widget), warnIfMissed: false);
      }
      await tester.pump();
      expect(h.system.calls, isEmpty);
      expect(h.tools.calls, isEmpty);
      expect(h.config.read('lockscreen'), isEmpty);
    });
  }

  testWidgets('no visible text in any pane shows an issue number', (
    tester,
  ) async {
    final h = await pumpSettings(tester, height: 1300);
    final issue = RegExp(r'#\d{1,4}\b');
    for (final pane in PaneId.values) {
      h.navigation.openPane(pane);
      await settle(tester);
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final shown = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(issue.hasMatch(shown), isFalse, reason: '${pane.name}: $shown');
      }
    }
  });

  testWidgets('every pane builds in light and dark without errors', (
    tester,
  ) async {
    final h = await pumpSettings(tester);
    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      for (final pane in PaneId.values) {
        h.navigation.openPane(pane);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: pane.name);
      }
      for (final sub in SubPaneId.values) {
        h.navigation.openSub(sub, 'app\u001fApp');
        await tester.pump();
        expect(tester.takeException(), isNull, reason: sub.name);
        h.navigation.openPane(PaneId.general);
        await tester.pump();
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
