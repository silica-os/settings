// Kit parity of the app installation screens: Security card, Storage App Row, Default apps
// (docs/design/amalfi/app-installation.md, section 5), and what the controls do.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/app_install.dart';
import 'package:silica_settings/src/ui/app_install.dart';
import 'package:silica_settings/src/ui/grouped.dart' show GroupBox;
import 'package:silica_ui/silica_ui.dart';

import 'apps_settings_test.dart' show mockDaemon;
import 'fakes.dart';
import 'kit.dart';
import 'pane_helpers.dart';

/// [r] relative to the top left of [origin].
Rect rel(WidgetTester tester, Finder child, Finder origin) {
  final c = tester.getRect(child.first);
  final o = tester.getTopLeft(origin.first);
  return c.shift(-o);
}

void expectRect(Rect actual, Rect kit, {String? reason}) {
  expect(actual.left, closeTo(kit.left, 0.6), reason: '$reason left');
  expect(actual.top, closeTo(kit.top, 0.6), reason: '$reason top');
  expect(actual.width, closeTo(kit.width, 0.6), reason: '$reason width');
  expect(actual.height, closeTo(kit.height, 0.6), reason: '$reason height');
}

Finder removeButton(String? name) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      (w.properties.label?.startsWith('Remove “') ?? false) &&
      (name == null || w.properties.label == 'Remove “$name”'),
);

Object? trust(String method, List<List<Object>> blocked) =>
    method == 'Blocked' ? [blocked] : const [];

void main() {
  group('Privacy & Security › Security', () {
    Finder card(String key) => find.ancestor(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(GroupBox),
    );

    testWidgets('Default: the card is 552 × 48 with the pop-up at 292', (
      tester,
    ) async {
      mockDaemon(tester, (i, m, a) async => trust(m, const []));
      await pumpSettings(tester, pane: PaneId.privacy);
      await settle(tester);
      final kit = loadKit('security-card-default');
      final group = card('security app sources');
      expect(tester.getSize(group.first), kit.size);
      final popup = find.descendant(
        of: group,
        matching: find.byType(AmalfiPopUpButton<String>),
      );
      expectRect(rel(tester, popup, group), kit.layer('Pop-up').rect);
      final label = find.descendant(
        of: group,
        matching: find.text('Allow applications from'),
      );
      expect(
        rel(tester, label, group).left,
        kit.layer('Allow applications from').rect.left,
      );
      // No caption while the policy is not Anywhere; the standing help is.
      expect(
        find.text(
          'Set from the command line. Apps from anywhere open without a check.',
        ),
        findsNothing,
      );
    });

    testWidgets(
      'Blocked App: the most recent block, Open Anyway 116 wide, card 96',
      (tester) async {
        final opened = <String>[];
        mockDaemon(tester, (i, m, a) async {
          if (m == 'OpenAnyway') opened.add(a.first as String);
          return trust(m, [
            ['/Applications/Old.app', 'Old', 1700000000],
            ['/Applications/Lemon.app', 'Lemon', 1700000900],
          ]);
        });
        await pumpSettings(tester, pane: PaneId.privacy);
        await settle(tester);
        final kit = loadKit('security-card-blocked');
        final group = card('security blocked /Applications/Lemon.app');
        expect(find.text('“Old” was blocked to protect Silica.'), findsNothing);
        expect(tester.getSize(group.first), kit.size);
        final message = find.text('“Lemon” was blocked to protect Silica.');
        final blockedMaster = kit.layer('Blocked message').rect;
        expect(rel(tester, message, group).left, blockedMaster.left);
        expect(
          rel(tester, message, group).top,
          closeTo(blockedMaster.top, 1.5),
        );
        final button = find.descendant(
          of: group,
          matching: find.byType(AmalfiPushButton),
        );
        expectRect(
          rel(tester, button, group),
          kit.layer('Open Anyway').rect,
          reason: 'Open Anyway',
        );
        await tapRowButton(tester, 'security blocked /Applications/Lemon.app');
        expect(opened, ['/Applications/Lemon.app']);
      },
    );

    testWidgets(
      'Anywhere: pop-up 104 wide, checked, and the caption 8 under the card',
      (tester) async {
        mockDaemon(tester, (i, m, a) async => trust(m, const []));
        final h = await pumpSettings(tester, pane: PaneId.privacy);
        await h.services.settings.set('security.appSources', 'anywhere');
        await settle(tester);
        final kit = loadKit('security-card-anywhere');
        final group = card('security app sources');
        expect(tester.getSize(group.first), kit.layer('Card').size);
        final popup = find.descendant(
          of: group,
          matching: find.byType(AmalfiPopUpButton<String>),
        );
        expectRect(rel(tester, popup, group), kit.layer('Pop-up').rect);
        final caption = find.text(
          'Set from the command line. Apps from anywhere open without a check.',
        );
        final captionMaster = kit.layer('Caption').rect;
        expect(rel(tester, caption, group).left, captionMaster.left);
        expect(
          rel(tester, caption, group).top,
          closeTo(captionMaster.top, 1.5),
        );
        // The menu has the third item, checked; choosing another removes it.
        await tester.tap(popup.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final menu = find.byType(AmalfiMenu);
        expect(
          find.descendant(of: menu, matching: find.text('Flathub')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: menu, matching: find.text('Anywhere')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: menu, matching: find.byType(AmalfiGlyph)),
          findsOneWidget,
        );
      },
    );

    testWidgets('the pop-up sets Flathub, and back to trusted', (tester) async {
      mockDaemon(tester, (i, m, a) async => trust(m, const []));
      final h = await pumpSettings(tester, pane: PaneId.privacy);
      await settle(tester);
      await choose(tester, 'security app sources', 'Flathub');
      expect(h.settings.values['security.appSources'], 'flathub');
      await settle(tester);
      final popup = find.descendant(
        of: find.byKey(const ValueKey('security app sources')),
        matching: find.byType(AmalfiPopUpButton<String>),
      );
      expect(tester.getSize(popup.first).width, regularPopUpWidth('Flathub'));
      await choose(
        tester,
        'security app sources',
        'Flathub and identified developers',
      );
      expect(h.settings.values['security.appSources'], 'trusted');
    });
  });

  group('General › Storage › Applications', () {
    List<Object> entry(
      String id,
      String name,
      String kind,
      String path, {
      bool hidden = false,
      String icon = '',
    }) => [
      id,
      name,
      kind,
      path,
      {
        'id': id,
        'name': name,
        'exec': 'x',
        'kind': kind,
        'path': path,
        'no_display': hidden,
        'silica_icon': icon,
      },
    ];

    late Directory home;

    Future<Harness> pumpStorage(
      WidgetTester tester, {
      List<List<Object>>? apps,
      Map<String, int> sizes = const {},
      Future<Object?> Function(String, String, List)? other,
      Map<String, String> extraEnv = const {},
    }) async {
      mockDaemon(tester, (i, m, a) async {
        if (i == 'dev.frascella.Silica.Apps1' && m == 'List') {
          return [apps ?? const []];
        }
        if (other != null) return other(i, m, a);
        throw PlatformException(code: 'ServiceUnknown');
      });
      final h = await pumpSettings(
        tester,
        pane: PaneId.general,
        height: 1400,
        extraEnv: extraEnv,
        run: (exe, args) async {
          if (exe == 'du') return '${sizes[args.last] ?? 0}\t${args.last}\n';
          if (exe == 'flatpak') return 'flathub\n';
          return null;
        },
      );
      home = Directory(h.services.env['HOME']!);
      h.navigation.openSub(SubPaneId.storage);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      return h;
    }

    final lemon = entry(
      'dev.x.Lemon',
      'Lemon',
      'bundle',
      '/Applications/Lemon.app',
    );
    final mustache = entry(
      'dev.frascella.Mustache',
      'Mustache',
      'system',
      '/usr/Applications/Mustache.app',
    );

    testWidgets(
      'rows sorted by size with the kit layout; System has no button',
      (tester) async {
        await pumpStorage(
          tester,
          apps: [
            lemon,
            mustache,
            entry('org.x.Flat', 'Flat', 'flatpak', ''),
            entry('x.AppImage', 'Img', 'appimage', '/nonexistent/Img.AppImage'),
            entry(
              'plain',
              'Plain',
              'system',
              '/usr/share/applications/plain.desktop',
            ),
            entry(
              'hid',
              'Hidden',
              'bundle',
              '/Applications/Hidden.app',
              hidden: true,
            ),
          ],
          sizes: {
            '/Applications/Lemon.app': 184000000,
            '/usr/Applications/Mustache.app': 42000000,
          },
        );
        expect(find.text('Applications'), findsOneWidget);
        expect(find.text('Plain'), findsNothing);
        expect(find.text('Hidden'), findsNothing);
        // Largest first: Lemon, Mustache, then the ones that measure 0.
        final tops = [
          for (final id in ['dev.x.Lemon', 'dev.frascella.Mustache'])
            tester.getTopLeft(find.byKey(ValueKey('storage app $id'))).dy,
        ];
        expect(tops[0], lessThan(tops[1]));
        expect(find.text('Flatpak · flathub'), findsOneWidget);
        expect(find.text('App bundle'), findsOneWidget);
        expect(find.text('System app'), findsOneWidget);
        expect(find.text('AppImage'), findsOneWidget);

        final rest = loadKit('storage-app-row-rest');
        final row = find.byKey(const ValueKey('storage app dev.x.Lemon'));
        expect(tester.getSize(row).height, rest.size.height);
        expectRect(
          rel(
            tester,
            find.descendant(of: row, matching: find.byType(AmalfiAppIcon)),
            row,
          ),
          rest.layer('App icon').rect,
          reason: 'icon',
        );
        final name = rel(
          tester,
          find.descendant(of: row, matching: find.text('Lemon')),
          row,
        );
        expect(name.left, rest.layer('Name').rect.left);
        expect(name.top, rest.layer('Name').rect.top);
        final kind = rel(
          tester,
          find.descendant(of: row, matching: find.text('App bundle')),
          row,
        );
        expect(kind.left, rest.layer('Kind').rect.left);
        expect(kind.top, rest.layer('Kind').rect.top);
        final button = rel(
          tester,
          find.descendant(of: row, matching: removeButton('Lemon')),
          row,
        );
        expect(button.left, rest.layer('Trash button').rect.left);
        expect(button.size, rest.layer('Trash button').size);
        expect(button.center.dy, closeTo(rest.size.height / 2, 0.6));
        // The size ends 8 before the button.
        final size = rel(
          tester,
          find.descendant(of: row, matching: find.text('184 MB')),
          row,
        );
        final sizeMaster = rest.layer('Size').rect;
        expect(size.right, closeTo(sizeMaster.right, 0.6));
        expect(size.top, sizeMaster.top);

        final sys = loadKit('storage-app-row-system');
        final srow = find.byKey(
          const ValueKey('storage app dev.frascella.Mustache'),
        );
        expect(tester.getSize(srow).height, sys.size.height);
        expect(
          find.descendant(of: srow, matching: removeButton(null)),
          findsNothing,
        );
        final ssize = rel(
          tester,
          find.descendant(of: srow, matching: find.text('42.0 MB')),
          srow,
        );
        expect(ssize.right, closeTo(sys.layer('Size').rect.right, 0.6));
      },
    );

    testWidgets('Remove moves a bundle to the Trash', (tester) async {
      final bundle = Directory(
        '${Directory.systemTemp.path}/silica-test-${DateTime.now().microsecondsSinceEpoch}/Lemon.app',
      )..createSync(recursive: true);
      addTearDown(() {
        try {
          bundle.parent.deleteSync(recursive: true);
        } on FileSystemException {
          // Moved.
        }
      });
      await pumpStorage(
        tester,
        apps: [entry('dev.x.Lemon', 'Lemon', 'bundle', bundle.path)],
      );
      await tester.tap(removeButton('Lemon'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      expect(bundle.existsSync(), isFalse);
      expect(
        Directory(
          '${home.path}/.local/share/Trash/files/Lemon.app',
        ).existsSync(),
        isTrue,
      );
    });

    testWidgets('Remove uninstalls a Flatpak app', (tester) async {
      final removed = <String>[];
      await pumpStorage(
        tester,
        apps: [entry('org.x.Flat', 'Flat', 'flatpak', '')],
        other: (i, m, a) async {
          if (m == 'Uninstall') {
            removed.add(a.first as String);
            return [true];
          }
          throw PlatformException(code: 'ServiceUnknown');
        },
      );
      await tester.tap(removeButton('Flat'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      expect(removed, ['org.x.Flat']);
    });

    testWidgets(
      'a running app asks Quit and Move; Cancel is the default and keeps it',
      (tester) async {
        final run = Directory.systemTemp.createTempSync('run');
        addTearDown(() => run.deleteSync(recursive: true));
        final child = (await tester.runAsync(
          () => Process.start('sleep', ['30']),
        ))!;
        addTearDown(child.kill);
        Directory('${run.path}/silica-apps').createSync();
        File(
          '${run.path}/silica-apps/dev.x.Lemon.${child.pid}.sock',
        ).createSync();
        final bundle = Directory('${run.path}/Lemon.app')..createSync();
        await pumpStorage(
          tester,
          apps: [entry('dev.x.Lemon', 'Lemon', 'bundle', bundle.path)],
          extraEnv: {'XDG_RUNTIME_DIR': run.path},
        );
        await tester.tap(removeButton('Lemon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text('“Lemon” is open. Quit it and move it to the Trash?'),
          findsOneWidget,
        );
        // Quit and Move (Secondary) then Cancel (Primary, the default).
        final quit = tester.getTopLeft(find.text('Quit and Move'));
        final cancel = tester.getTopLeft(find.text('Cancel'));
        expect(quit.dx, lessThan(cancel.dx));
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        expect(bundle.existsSync(), isTrue);
        expect(Directory('/proc/${child.pid}').existsSync(), isTrue);

        // Again, and this time quit it.
        await tester.tap(removeButton('Lemon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Quit and Move'));
        await tester.pump();
        await tester.runAsync(
          () => child.exitCode.timeout(const Duration(seconds: 5)),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await settle(tester);
        expect(bundle.existsSync(), isFalse);
        expect(
          Directory(
            '${home.path}/.local/share/Trash/files/Lemon.app',
          ).existsSync(),
          isTrue,
        );
      },
    );
  });

  group('Desktop & Dock › Default apps', () {
    Future<List<String>> pumpDefaults(WidgetTester tester) async {
      final set = <String>[];
      mockDaemon(tester, (interface, method, args) async {
        if (interface != 'dev.frascella.Silica.Apps1') {
          throw PlatformException(code: 'ServiceUnknown');
        }
        const names = {
          'dev.x.Silica': 'Silica Web',
          'org.x.Aurora': 'Aurora',
          'dev.x.Heron': 'Heron',
          'dev.frascella.Mustache': 'Mustache',
        };
        return switch (method) {
          'List' => [
            [
              for (final e in names.entries)
                [
                  e.key,
                  e.value,
                  'system',
                  '/x',
                  {'id': e.key, 'name': e.value, 'exec': 'x'},
                ],
            ],
          ],
          'AppsFor' => [
            switch (args.first) {
              'x-scheme-handler/http' => [
                'dev.x.Silica',
                'org.x.Aurora',
                'dev.x.Heron',
              ],
              'text/plain' => ['dev.frascella.Mustache'],
              _ => <String>[],
            },
          ],
          'DefaultFor' => [
            switch (args.first) {
              'x-scheme-handler/http' => 'dev.x.Silica',
              'text/plain' => 'dev.frascella.Mustache',
              _ => '',
            },
          ],
          'SetDefault' => () {
            set.add('${args[0]} ${args[1]}');
            return const [];
          }(),
          _ => const [],
        };
      });
      await pumpSettings(tester, pane: PaneId.desktopDock, height: 2400);
      await settle(tester);
      return set;
    }

    testWidgets('the card has the rows that something opens, no Terminal', (
      tester,
    ) async {
      await pumpDefaults(tester);
      expect(find.text('Default apps'), findsOneWidget);
      expect(find.text('Web browser'), findsOneWidget);
      expect(find.text('Text editor'), findsOneWidget);
      // Nothing opens mail or images here: those rows are not shown. Nothing in Silica
      // consumes a default terminal: there is no such row.
      expect(find.text('Mail'), findsNothing);
      expect(find.text('Image viewer'), findsNothing);
      expect(find.text('Terminal'), findsNothing);
    });

    testWidgets(
      'App pop-up: icon 16 at x 12 in a 20 slot, label at x 36, width text + 64',
      (tester) async {
        await pumpDefaults(tester);
        final master = loadKit('popup-app-regular');
        final popup = find.descendant(
          of: find.byKey(const ValueKey('default app x-scheme-handler/http')),
          matching: find.byType(AppPopUp),
        );
        final size = tester.getSize(popup);
        expect(size.height, master.size.height);
        expect(size.width, appPopUpWidth('Silica Web'));
        final icon = rel(
          tester,
          find.descendant(of: popup, matching: find.byType(AmalfiAppIcon)),
          popup,
        );
        expect(icon.left, master.layer('Icon slot').rect.left);
        final label = rel(
          tester,
          find.descendant(of: popup, matching: find.text('Silica Web')),
          popup,
        );
        expect(label.left, master.layer('Label').rect.left);
        // The pop-up ends 12 from the card's edge (kit Default Apps Card).
        final card = find.ancestor(of: popup, matching: find.byType(GroupBox));
        expect(
          tester.getRect(card.first).right - tester.getRect(popup).right,
          12,
        );
        final cardMaster = loadKit('default-apps-card');
        expect(cardMaster.layer('Pop-up Web browser').rect.right, 540);
      },
    );

    testWidgets(
      'the menu lists the apps sorted by name with the default checked',
      (tester) async {
        final set = await pumpDefaults(tester);
        final popup = find.descendant(
          of: find.byKey(const ValueKey('default app x-scheme-handler/http')),
          matching: find.byType(AppPopUp),
        );
        await tester.tap(popup);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final menu = find.byType(AmalfiMenu);
        final order = [
          for (final name in ['Aurora', 'Heron', 'Silica Web'])
            tester
                .getTopLeft(
                  find.descendant(of: menu, matching: find.text(name)),
                )
                .dy,
        ];
        expect(order[0], lessThan(order[1]));
        expect(order[1], lessThan(order[2]));
        expect(
          find.descendant(of: menu, matching: find.byType(AmalfiAppIcon)),
          findsNWidgets(3),
        );
        await tester.tap(
          find.descendant(of: menu, matching: find.text('Aurora')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(set, ['x-scheme-handler/http org.x.Aurora']);
        await settle(tester);
        expect(
          find.descendant(of: popup, matching: find.text('Aurora')),
          findsOneWidget,
        );
      },
    );

    testWidgets('the Image viewer sets every image type', (tester) async {
      final set = <String>[];
      mockDaemon(tester, (interface, method, args) async {
        return switch (method) {
          'List' => [
            [
              [
                'org.x.View',
                'View',
                'system',
                '/x',
                {'id': 'org.x.View', 'name': 'View', 'exec': 'x'},
              ],
              [
                'org.x.Eye',
                'Eye',
                'system',
                '/x',
                {'id': 'org.x.Eye', 'name': 'Eye', 'exec': 'x'},
              ],
            ],
          ],
          'AppsFor' => [
            args.first == 'image/png'
                ? ['org.x.View', 'org.x.Eye']
                : <String>[],
          ],
          'DefaultFor' => ['org.x.View'],
          'SetDefault' => () {
            set.add('${args[0]} ${args[1]}');
            return const [];
          }(),
          _ => const [],
        };
      });
      await pumpSettings(tester, pane: PaneId.desktopDock, height: 2400);
      await settle(tester);
      final popup = find.descendant(
        of: find.byKey(const ValueKey('default app image/png')),
        matching: find.byType(AppPopUp),
      );
      await tester.tap(popup);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.descendant(
          of: find.byType(AmalfiMenu),
          matching: find.text('Eye'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(set, [for (final t in imageTypes) '$t org.x.Eye']);
    });
  });

  group('General › Software Update', () {
    testWidgets('auto-check and auto-install toggles (Settings1 updates.*)', (
      tester,
    ) async {
      mockDaemon(
        tester,
        (i, m, a) async => throw PlatformException(code: 'ServiceUnknown'),
      );
      final h = await pumpSettings(tester, pane: PaneId.general);
      h.navigation.openSub(SubPaneId.softwareUpdate);
      await settle(tester);
      expect(find.text('Check for updates automatically'), findsOneWidget);
      expect(find.text('Install updates automatically'), findsOneWidget);
      // Defaults: checking on, installing off.
      expect(
        tester.widget<AmalfiSwitch>(switchIn('update auto check')).value,
        isTrue,
      );
      expect(
        tester.widget<AmalfiSwitch>(switchIn('update auto install')).value,
        isFalse,
      );
      await tester.tap(switchIn('update auto install'));
      await settle(tester);
      expect(h.settings.values['updates.autoInstall'], true);
      await tester.tap(switchIn('update auto check'));
      await settle(tester);
      expect(h.settings.values['updates.autoCheck'], false);
      // With checking off, installing is disabled: it does not change.
      expect(
        tester.widget<AmalfiSwitch>(switchIn('update auto install')).onChanged,
        isNull,
      );
      await tester.tap(switchIn('update auto install'), warnIfMissed: false);
      await settle(tester);
      expect(h.settings.values['updates.autoInstall'], true);
    });
  });
}
