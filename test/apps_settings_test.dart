// Software Update (Updates1), the app data in Storage and the default apps (Apps1).

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/ui/app_install.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void mockDaemon(
  WidgetTester tester,
  Future<Object?> Function(String interface, String method, List args) answer,
) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SilicaDBus.channel,
    (call) async {
      if (call.method != 'call') return null;
      final args = call.arguments as Map;
      return answer(
        '${args['interface']}',
        '${args['method']}',
        (args['args'] as List?) ?? const [],
      );
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SilicaDBus.channel,
      null,
    ),
  );
}

void main() {
  testWidgets('Software Update lists the updates and installs one', (
    tester,
  ) async {
    final installed = <String>[];
    mockDaemon(tester, (interface, method, args) async {
      if (interface != 'dev.frascella.Silica.Updates1') {
        throw PlatformException(code: 'ServiceUnknown');
      }
      return switch (method) {
        'Check' => [
          [
            [
              'dev.example.Hello',
              'bundle',
              'Hello',
              '1.0',
              '1.1',
              {'size': 10},
            ],
            ['system', 'system', 'Silica', '0.2.0', '0.3.0', {}],
          ],
        ],
        'Update' => () {
          installed.add(args.first as String);
          return [args.first == 'system' ? 'staged' : 'installed'];
        }(),
        _ => const [],
      };
    });
    final h = await pumpSettings(tester, pane: PaneId.general);
    h.navigation.openSub(SubPaneId.softwareUpdate);
    await settle(tester);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('1.0 → 1.1'), findsOneWidget);
    await tapRowButton(tester, 'update dev.example.Hello');
    await settle(tester);
    expect(installed, ['dev.example.Hello']);
    expect(find.text('Updated.'), findsOneWidget);
    await tapRowButton(tester, 'update system');
    await settle(tester);
    expect(find.text('Restart to finish the update.'), findsOneWidget);
  });

  testWidgets('Storage shows app data; data of removed apps can be deleted', (
    tester,
  ) async {
    mockDaemon(tester, (interface, method, args) async {
      if (interface == 'dev.frascella.Silica.Apps1' && method == 'List') {
        return [
          [
            [
              'dev.example.Kept',
              'Kept',
              'system',
              '/x',
              {'id': 'dev.example.Kept', 'name': 'Kept', 'exec': 'x'},
            ],
          ],
        ];
      }
      throw PlatformException(code: 'ServiceUnknown');
    });
    final h = await pumpSettings(
      tester,
      pane: PaneId.general,
      run: (exe, args) async => exe == 'du' ? '4096\t.\n' : null,
    );
    final home = h.services.env['HOME']!;
    for (final id in ['dev.example.Kept', 'dev.example.Gone']) {
      Directory('$home/.var/app/$id/data').createSync(recursive: true);
    }
    h.navigation.openSub(SubPaneId.storage);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.text('Kept'), findsOneWidget);
    expect(find.text('dev.example.Gone (not installed)'), findsOneWidget);
    // An installed app keeps its data: no Delete.
    expect(
      find.byKey(const ValueKey('delete data dev.example.Kept')),
      findsNothing,
    );
    await tapKey(tester, 'delete data dev.example.Gone');
    await tester.tap(find.text('Delete').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(Directory('$home/.var/app/dev.example.Gone').existsSync(), isFalse);
    expect(Directory('$home/.var/app/dev.example.Kept').existsSync(), isTrue);
  });

  testWidgets('default apps come from the registry and are set there', (
    tester,
  ) async {
    final set = <String>[];
    mockDaemon(tester, (interface, method, args) async {
      if (interface != 'dev.frascella.Silica.Apps1') {
        throw PlatformException(code: 'ServiceUnknown');
      }
      return switch (method) {
        'List' => [
          [
            for (final (id, name) in [
              ('dev.frascella.Preview', 'Preview'),
              ('org.gnome.Papers', 'Papers'),
            ])
              [
                id,
                name,
                'system',
                '/x',
                {'id': id, 'name': name, 'exec': 'x'},
              ],
          ],
        ],
        'AppsFor' => [
          args.first == 'text/plain'
              ? ['dev.frascella.Preview', 'org.gnome.Papers']
              : <String>[],
        ],
        'DefaultFor' => [
          args.first == 'text/plain' ? 'dev.frascella.Preview' : '',
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
    expect(find.text('Text editor'), findsOneWidget);
    // Kinds no app opens are not offered.
    expect(find.text('Image viewer'), findsNothing);
    await tester.tap(find.byType(AppPopUp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(AmalfiMenu),
        matching: find.text('Papers'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(set, ['text/plain org.gnome.Papers']);
  });
}
