// App installation in Settings: the Storage › Applications list (sorting, kinds), removal
// (Trash, running apps), the security policy values and the pop-up width rules.

import 'dart:io';

import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/system/app_install.dart';
import 'package:silica_ui/silica_ui.dart';

import 'kit.dart';

SilicaInstalledApp app(
  String id,
  SilicaInstalledAppKind kind, {
  String path = '',
  bool noDisplay = false,
  String icon = '',
}) => SilicaInstalledApp(
  id: id,
  name: id.toUpperCase(),
  kind: kind,
  path: path,
  noDisplay: noDisplay,
  silicaIcon: icon,
);

void main() {
  group('the installed apps of Storage', () {
    test('bundles, AppImages, Flatpaks and system bundles; nothing else', () {
      final list = storageApps([
        app('a', SilicaInstalledAppKind.bundle, path: '/Applications/A.app'),
        app(
          'b',
          SilicaInstalledAppKind.appimage,
          path: '/Applications/B.AppImage',
        ),
        app('c', SilicaInstalledAppKind.flatpak, path: '/ignored'),
        app(
          'd',
          SilicaInstalledAppKind.system,
          path: '/usr/Applications/D.app',
        ),
        // A plain desktop entry is not a bundle.
        app(
          'e',
          SilicaInstalledAppKind.system,
          path: '/usr/share/applications/e.desktop',
        ),
        // Hidden from the Launcher.
        app(
          'f',
          SilicaInstalledAppKind.bundle,
          path: '/Applications/F.app',
          noDisplay: true,
        ),
      ]);
      expect([for (final a in list) a.id], ['a', 'b', 'c', 'd']);
      expect(
        [for (final a in list) a.kind],
        [
          StorageAppKind.bundle,
          StorageAppKind.appImage,
          StorageAppKind.flatpak,
          StorageAppKind.system,
        ],
      );
      expect(list[2].path, isEmpty);
      expect([for (final a in list) a.removable], [true, true, true, false]);
    });

    test('the icon is the app\'s own, else its id', () {
      final list = storageApps([
        app('a', SilicaInstalledAppKind.bundle, path: '/x.app', icon: 'notes'),
        app('b', SilicaInstalledAppKind.bundle, path: '/y.app'),
      ]);
      expect([for (final a in list) a.icon], ['notes', 'b']);
    });

    test('sorted by size, largest first; unmeasured last; ties by name', () {
      StorageApp s(String id, int? size) => StorageApp(
        id: id,
        name: id,
        icon: id,
        kind: StorageAppKind.bundle,
        path: '/$id',
        size: size,
      );
      final sorted = sortedBySize([
        s('b', 10),
        s('z', null),
        s('a', 10),
        s('big', 1000),
        s('c', null),
      ]);
      expect([for (final a in sorted) a.id], ['big', 'a', 'b', 'c', 'z']);
    });

    test('kind lines', () {
      String label(StorageAppKind kind, [String? remote]) => storageKindLabel(
        kind: kind,
        remote: remote,
        bundle: 'App bundle',
        flatpak: 'Flatpak',
        appImage: 'AppImage',
        system: 'System app',
      );
      expect(label(StorageAppKind.bundle), 'App bundle');
      expect(label(StorageAppKind.appImage), 'AppImage');
      expect(label(StorageAppKind.system), 'System app');
      expect(label(StorageAppKind.flatpak, 'flathub'), 'Flatpak · flathub');
      expect(label(StorageAppKind.flatpak), 'Flatpak');
      expect(label(StorageAppKind.flatpak, ''), 'Flatpak');
    });

    test('Flatpak folders: system, then the user installation', () {
      expect(flatpakFolders('org.x.App', {'HOME': '/home/ada'}), [
        '/var/lib/flatpak/app/org.x.App/current/active',
        '/home/ada/.local/share/flatpak/app/org.x.App/current/active',
      ]);
    });

    test('sizes: AppImage file, bundle and Flatpak folders', () async {
      final dir = Directory.systemTemp.createTempSync('sizes');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/X.AppImage').writeAsBytesSync(List.filled(123, 0));
      final flatpak = Directory(
        '${dir.path}/.local/share/flatpak/app/org.x.App/current/active',
      )..createSync(recursive: true);
      final env = {'HOME': dir.path};
      final asked = <String>[];
      Future<String?> run(String exe, List<String> args) async {
        asked.add('$exe ${args.join(' ')}');
        return '4096\t${args.last}\n';
      }

      StorageApp s(StorageAppKind k, String path) => StorageApp(
        id: 'org.x.App',
        name: 'X',
        icon: 'x',
        kind: k,
        path: path,
      );
      expect(
        await measureApp(
          run,
          s(StorageAppKind.appImage, '${dir.path}/X.AppImage'),
          env,
        ),
        123,
      );
      expect(
        await measureApp(run, s(StorageAppKind.bundle, '/A.app'), env),
        4096,
      );
      expect(await measureApp(run, s(StorageAppKind.flatpak, ''), env), 4096);
      expect(asked, ['du -sb /A.app', 'du -sb ${flatpak.path}']);
      expect(
        await measureApp(
          run,
          s(StorageAppKind.appImage, '${dir.path}/none'),
          env,
        ),
        isNull,
      );
    });
  });

  group('removing', () {
    late Directory home;
    late Map<String, String> env;

    setUp(() {
      home = Directory.systemTemp.createTempSync('trash-home');
      env = {'HOME': home.path};
    });
    tearDown(() => home.deleteSync(recursive: true));

    test('a bundle goes to the Trash with its .trashinfo', () async {
      final bundle = Directory('${home.path}/Applications/Lemon.app')
        ..createSync(recursive: true);
      File('${bundle.path}/exec').writeAsStringSync('x');
      expect(await moveToTrash(env, bundle.path), isNull);
      final trash = '${home.path}/.local/share/Trash';
      expect(bundle.existsSync(), isFalse);
      expect(File('$trash/files/Lemon.app/exec').existsSync(), isTrue);
      final info = File('$trash/info/Lemon.app.trashinfo').readAsStringSync();
      expect(
        info,
        startsWith('[Trash Info]\nPath=${home.path}/Applications/Lemon.app\n'),
      );
      expect(
        info,
        contains(RegExp(r'DeletionDate=\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\n')),
      );
    });

    test('an AppImage too; the name is kept unique and encoded', () async {
      final trash = '${home.path}/.local/share/Trash';
      Directory('$trash/files/My App.AppImage').createSync(recursive: true);
      final file = File('${home.path}/Applications/My App.AppImage')
        ..createSync(recursive: true);
      expect(await moveToTrash(env, file.path), isNull);
      expect(File('$trash/files/My App.AppImage 2').existsSync(), isTrue);
      expect(
        File('$trash/info/My App.AppImage 2.trashinfo').readAsStringSync(),
        contains('Path=${home.path}/Applications/My%20App.AppImage\n'),
      );
    });

    test('a missing app is an error, not a crash', () async {
      expect(await moveToTrash(env, '${home.path}/none.app'), isNotNull);
      expect(
        Directory('${home.path}/.local/share/Trash/info').listSync(),
        isEmpty,
      );
    });

    test('a running app: a live pid in the app socket folder', () {
      final run = Directory('${home.path}/run/silica-apps')
        ..createSync(recursive: true);
      final e = {...env, 'XDG_RUNTIME_DIR': '${home.path}/run'};
      expect(runningPid(e, 'dev.x.Lemon'), isNull);
      File('${run.path}/dev.x.Lemon.$pid.sock').createSync();
      File('${run.path}/dev.x.Lemon2.$pid.sock').createSync();
      File('${run.path}/dev.x.Other.999999999.sock').createSync();
      expect(runningPid(e, 'dev.x.Lemon'), pid);
      expect(runningPid(e, 'dev.x.Lem'), isNull);
      // A stale socket whose process is gone does not count.
      expect(runningPid(e, 'dev.x.Other'), isNull);
      expect(runningPid({'HOME': home.path}, 'dev.x.Lemon'), isNull);
    });

    test('quitting sends SIGTERM and waits for the process to go', () async {
      final child = await Process.start('sleep', ['30']);
      addTearDown(child.kill);
      expect(await quitProcess(child.pid), isTrue);
      expect(Directory('/proc/${child.pid}').existsSync(), isFalse);
    });

    test('a process that stays is reported after the timeout', () async {
      var signalled = 0;
      final done = await quitProcess(
        pid,
        timeout: const Duration(milliseconds: 150),
        poll: const Duration(milliseconds: 20),
        signal: (_) => ++signalled > 0,
      );
      expect(done, isFalse);
      expect(signalled, 1);
    });
  });

  group('security policy and pop-up widths', () {
    test('the pop-up offers Flathub and trusted; anywhere only while set', () {
      expect(appSourceValues('trusted'), ['flathub', 'trusted']);
      expect(appSourceValues('flathub'), ['flathub', 'trusted']);
      expect(appSourceValues('anywhere'), ['flathub', 'trusted', 'anywhere']);
    });

    test('hug: text + extra, rounded up to 4', () {
      expect(hugWidth(100, 40), 140);
      expect(hugWidth(100.1, 40), 144);
      expect(hugWidth(0, 64), 64);
    });

    test('Regular pop-up: text + 40 matches the Security masters', () {
      final card = loadKit('security-card-default');
      expect(
        regularPopUpWidth('Flathub and identified developers'),
        card.layer('Pop-up').size.width,
      );
      expect(
        regularPopUpWidth('Anywhere'),
        loadKit('security-card-anywhere').layer('Pop-up').size.width,
      );
    });

    test('App pop-up: text + 64, rounded up to 4', () {
      final master = loadKit('popup-app-regular');
      // The master's label box is 100 wide: 36 + 100 + 28 = the pop-up.
      expect(master.size.width, 164);
      expect(master.layer('Label').rect.left, 36);
      expect(master.layer('Icon slot').rect, Rect.fromLTWH(12, 6, 20, 16));
      for (final name in ['Silica Web', 'Aurora', 'Heron', 'Mail']) {
        final w = appPopUpWidth(name);
        expect(w % 4, 0, reason: name);
        expect(w, greaterThanOrEqualTo(appPopUpWidth('')), reason: name);
      }
      expect(appPopUpWidth('Heron'), lessThan(appPopUpWidth('Silica Web')));
    });

    test('the choices of a Default apps pop-up are sorted by name', () {
      final installed = {
        'b': app('b', SilicaInstalledAppKind.bundle, icon: 'bee'),
        'a': app('a', SilicaInstalledAppKind.bundle),
      };
      final choices = defaultAppChoices(['b', 'x', 'a'], installed);
      expect([for (final c in choices) c.id], ['a', 'b', 'x']);
      expect([for (final c in choices) c.icon], ['a', 'bee', 'x']);
      expect(imageTypes, contains('image/svg+xml'));
      expect(imageTypes, hasLength(7));
    });
  });
}
