// Settings' menus in Silica's menu bar (silica-menu-v1): the model published on `silica/menu`,
// the choices that come back and the ⌘ shortcuts.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_ui/silica_ui.dart' show SilicaMenuDelegate;

import 'fakes.dart';

void main() {
  late List<MethodCall> calls;

  Future<Harness> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    PaneId pane = PaneId.wifi,
  }) async {
    calls = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SilicaMenuDelegate.defaultChannel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SilicaMenuDelegate.defaultChannel,
        null,
      ),
    );
    final h = await pumpSettings(tester, locale: locale, pane: pane);
    await tester.pump();
    return h;
  }

  List<Map<Object?, Object?>> menus() =>
      ((calls.lastWhere((c) => c.method == 'setMenus').arguments
                  as Map)['menus']
              as List)
          .cast<Map<Object?, Object?>>();

  List<Map<Object?, Object?>> items(String menu) =>
      (menus().firstWhere((m) => m['label'] == menu)['items'] as List)
          .cast<Map<Object?, Object?>>();

  Map<Object?, Object?> item(String menu, String label) =>
      items(menu).firstWhere((i) => i['label'] == label);

  Map<Object?, Object?> role(String menu, String role) =>
      items(menu).firstWhere((i) => i['role'] == role);

  bool on(Map<Object?, Object?> i) => i['enabled'] != false;

  Future<void> choose(WidgetTester tester, Object? id) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SilicaMenuDelegate.defaultChannel.name,
      const JSONMethodCodec().encodeMethodCall(MethodCall('activated', id)),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('the menus as measured: app, Edit, View, Window, Help', (
    tester,
  ) async {
    await pump(tester);
    expect(menus().map((m) => m['label']), [
      'Settings',
      'Edit',
      'View',
      'Window',
      // The standard Help menu (silica-ui#99): the bar gives its title.
      '',
    ]);
    // About only: no Settings item, no File menu.
    expect(items('Settings').map((i) => i['role']), contains('about'));
    expect(
      items('Settings').map((i) => i['role']),
      isNot(contains('settings')),
    );
    expect(items('Settings').map((i) => i['role']), contains('quit'));
  });

  testWidgets('Edit: text items disabled until the search field has focus', (
    tester,
  ) async {
    await pump(tester);
    for (final r in ['undo', 'redo', 'cut', 'copy', 'paste', 'delete']) {
      expect(on(role('Edit', r)), isFalse, reason: r);
    }
    expect(on(role('Edit', 'select_all')), isFalse);
    for (final label in [
      'Writing Tools',
      'AutoFill',
      'Start Dictation…',
      'Emoji & Symbols',
    ]) {
      expect(on(item('Edit', label)), isFalse, reason: label);
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(on(role('Edit', 'paste')), isTrue);
    expect(on(role('Edit', 'select_all')), isTrue);
    expect(on(role('Edit', 'copy')), isFalse);
  });

  testWidgets('View: back and forward follow the history, ⌘F focuses search', (
    tester,
  ) async {
    final h = await pump(tester);
    expect(on(item('View', 'Back')), isFalse);
    expect(on(item('View', 'Forward')), isFalse);
    h.navigation.openPane(PaneId.sound);
    await tester.pump();
    expect(on(item('View', 'Back')), isTrue);
    await choose(tester, item('View', 'Back')['id']);
    expect(h.navigation.pane, PaneId.wifi);
    expect(on(item('View', 'Forward')), isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(h.navigation.pane, PaneId.sound);
    expect(item('View', 'Back')['shortcut'], isNotNull);
    expect(item('View', 'Search')['shortcut'], isNotNull);
  });

  testWidgets('View lists the panes alphabetically, the current one checked', (
    tester,
  ) async {
    final h = await pump(tester);
    final names = items('View')
        .map((i) => i['label'])
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .skipWhile((n) => n != 'Search')
        .skip(1)
        .toList();
    final panes = names.takeWhile((n) => n != 'Enter Full Screen').toList();
    expect(panes.first, 'Accessibility');
    final sorted = [...panes]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    expect(panes, sorted);
    expect(item('View', 'Wi-Fi')['checked'], isTrue);
    expect(item('View', 'Sound')['checked'], isNot(true));
    await choose(tester, item('View', 'Sound')['id']);
    expect(h.navigation.pane, PaneId.sound);
    expect(item('View', 'Sound')['checked'], isTrue);
    expect(item('View', 'Wi-Fi')['checked'], isNot(true));
    expect(on(role('View', 'fullscreen')), isFalse);
  });

  testWidgets('About opens General › About', (tester) async {
    final h = await pump(tester);
    await choose(tester, role('Settings', 'about')['id']);
    expect(
      h.navigation.location,
      const Location(PaneId.general, SubPaneId.about),
    );
  });

  testWidgets('the menus are translated', (tester) async {
    await pump(tester, locale: const Locale('it'));
    expect(menus().map((m) => m['label']), contains('Modifica'));
    expect(menus().map((m) => m['label']), contains('Vista'));
    expect(item('Vista', 'Indietro'), isNotNull);
  });
}
