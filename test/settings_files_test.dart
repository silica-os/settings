// What Settings writes for Ossido and silica-daemon: keyboard.* and input.* of the Settings
// service, and the files sound, power and focus: ranges, kept keys, and broken input.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/settings_files.dart';

ConfigStore store() => ConfigStore(
  '${Directory.systemTemp.createTempSync('settings-files').path}/silica',
);

Object? file(ConfigStore c, String name) =>
    jsonDecode(File('${c.directory}/$name.json').readAsStringSync());

void main() {
  group('keyboard.* of the Settings service (silica-desktop#240)', () {
    test('repeat values are clamped to Ossido\'s ranges', () async {
      final backend = MemorySettingsBackend({});
      final s = SilicaSettings(backend: backend);
      await s.writeRepeatDelay(5);
      await s.writeRepeatRate(500);
      expect(backend.writes.last, 'keyboard.repeatRate');
      expect(s.savedRepeatDelay, 100);
      await s.writeRepeatDelay(99999);
      await s.writeRepeatRate(-3);
      expect(s.savedRepeatDelay, 3000);
      expect(s.savedRepeatRate, 0);
    });

    test('before the service answers the saved values are null', () {
      final s = SilicaSettings(backend: MemorySettingsBackend({}));
      expect(s.savedRepeatDelay, isNull);
      expect(s.savedRepeatRate, isNull);
    });

    test('layouts: at most four, empty is xkb\'s default', () async {
      final s = SilicaSettings(backend: MemorySettingsBackend({}));
      await s.writeLayouts(['us', 'it', 'de(nodeadkeys)', 'fr', 'es']);
      expect(s.savedLayouts, ['us', 'it', 'de(nodeadkeys)', 'fr']);
      await s.writeLayouts([]);
      expect(s.savedLayouts, isEmpty);
    });

    test('layout ids join and split on the variant', () {
      expect(layoutId('de', 'nodeadkeys'), 'de(nodeadkeys)');
      expect(layoutId('it'), 'it');
      expect(splitLayout('de(nodeadkeys)'), ('de', 'nodeadkeys'));
      expect(splitLayout('it'), ('it', ''));
    });
  });

  group('input.* of the Settings service (silica-desktop#240)', () {
    test('one key of one device; null goes back to the default', () async {
      final backend = MemorySettingsBackend({});
      final s = SilicaSettings(backend: backend);
      await s.writePointer(PointerDevice.mouse, 'naturalScroll', true);
      await s.writePointer(PointerDevice.touchpad, 'tapToClick', true);
      await s.writePointerSpeed(PointerDevice.mouse, 0.456);
      await s.writeScrollSpeed(PointerDevice.touchpad, 25);
      expect(
        s.pointerFlag(PointerDevice.mouse, 'naturalScroll', fallback: false),
        isTrue,
      );
      expect(s.pointerSpeed(PointerDevice.mouse), 0.46);
      expect(s.pointerScrollSpeed(PointerDevice.touchpad), 10.0);
      expect(backend.writes, [
        'input.mouse.naturalScroll',
        'input.touchpad.tapToClick',
        'input.mouse.speed',
        'input.touchpad.scrollSpeed',
      ]);
      await s.writePointer(PointerDevice.mouse, 'naturalScroll', null);
      expect(backend.writes.last, 'input.mouse.naturalScroll');
      expect(
        s.pointerFlag(PointerDevice.mouse, 'naturalScroll', fallback: false),
        isFalse,
      );
    });

    test('a value that is not a number writes nothing', () async {
      final backend = MemorySettingsBackend({});
      final s = SilicaSettings(backend: backend);
      expect(
        await s.writePointerSpeed(PointerDevice.mouse, double.nan),
        isFalse,
      );
      expect(
        await s.writeScrollSpeed(PointerDevice.mouse, double.infinity),
        isFalse,
      );
      expect(backend.writes, isEmpty);
      final c = store();
      expect(c.writeAlertVolume(double.nan), isFalse);
      expect(c.read('sound'), isEmpty);
    });

    test('reads fall back to the defaults', () {
      final s = SilicaSettings.withValues({'input.mouse.speed': 'broken'});
      expect(s.pointerSpeed(PointerDevice.mouse), 0);
      expect(s.pointerScrollSpeed(PointerDevice.touchpad), 1);
      expect(
        s.pointerFlag(
          PointerDevice.touchpad,
          'disableWhileTyping',
          fallback: true,
        ),
        isTrue,
      );
    });
  });

  test('sound.json and power.json keep their other keys', () {
    final c = store()
      ..write('sound', 'uiSounds', false)
      ..writeAlertVolume(1.7)
      ..write('power', 'preventSleep', true)
      ..writeIdleMinutes('sleepMinutes', 30)
      ..writeIdleMinutes('displayOffMinutes', -5);
    expect(file(c, 'sound'), {'uiSounds': false, 'alertVolume': 1.0});
    expect(file(c, 'power'), {
      'preventSleep': true,
      'sleepMinutes': 30,
      'displayOffMinutes': 0,
    });
    expect(c.idleMinutes('sleepMinutes'), 30);
    expect(c.idleMinutes('displayOffMinutes'), 0);
    expect(c.alertVolume, 1);
  });

  group('focus.json', () {
    test('ids come from the name and never repeat or take dnd', () {
      expect(FocusMode.idFor('Deep Work!', []), 'deep-work');
      expect(FocusMode.idFor('Work', ['work', 'work-2']), 'work-3');
      expect(FocusMode.idFor('DND', []), 'focus');
      expect(FocusMode.idFor('日本', []), 'focus');
    });

    test('modes are written whole and `active` is kept', () {
      final c = store()..write('focus', 'active', 'work');
      c.writeFocusModes([
        const FocusMode(
          id: 'work',
          name: 'Work',
          symbol: 'person',
          allowedApps: ['firefox'],
          allowedPeople: ['Ada'],
        ),
      ]);
      expect(file(c, 'focus'), {
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
      expect(c.focusModes.single.allowedPeople, ['Ada']);
    });

    test('a broken, reserved or repeated mode is skipped; 32 at most', () {
      final c = store()
        ..write('focus', 'modes', [
          'nope',
          {'name': 'No id'},
          {'id': 'dnd', 'name': 'Reserved'},
          {
            'id': 'a',
            'name': 'A',
            'allowedApps': [1, 'x', ''],
          },
          {'id': 'a', 'name': 'Again'},
          {'id': 'b'},
        ]);
      final modes = c.focusModes;
      expect([for (final m in modes) m.id], ['a', 'b']);
      expect(modes.first.allowedApps, ['x']);
      expect(modes.last.name, 'b');
      expect(modes.last.symbol, 'moon');
      c.writeFocusModes([
        for (var i = 0; i < 40; i++) FocusMode(id: 'm$i', name: 'M$i'),
      ]);
      expect(c.focusModes, hasLength(32));
    });
  });
}
