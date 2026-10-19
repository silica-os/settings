// Privacy & Security: where apps may come from, and Open Anyway (Gatekeeper, Trust1).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  testWidgets('app sources and Open Anyway for a blocked app', (tester) async {
    final opened = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SilicaDBus.channel,
      (call) async {
        if (call.method != 'call') return null;
        final args = call.arguments as Map;
        if (args['interface'] != 'dev.frascella.Silica.Trust1') {
          throw PlatformException(
            code: 'org.freedesktop.DBus.Error.ServiceUnknown',
          );
        }
        switch (args['method']) {
          case 'Blocked':
            return [
              if (opened.isEmpty)
                [
                  ['/home/ada/Applications/Mine.app', 'Mine', 1700000000],
                ]
              else
                [],
            ];
          case 'OpenAnyway':
            opened.add((args['args'] as List).first as String);
            return [true];
        }
        return const [];
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SilicaDBus.channel,
        null,
      ),
    );
    final h = await pumpSettings(tester, pane: PaneId.privacy);
    await settle(tester);
    expect(find.text('Allow applications from'), findsOneWidget);
    expect(find.text('Flathub and identified developers'), findsOneWidget);
    expect(find.text('“Mine” was blocked to protect Silica.'), findsOneWidget);
    await tapRowButton(
      tester,
      'security blocked /home/ada/Applications/Mine.app',
    );
    await settle(tester);
    expect(opened, ['/home/ada/Applications/Mine.app']);
    expect(find.text('“Mine” was blocked to protect Silica.'), findsNothing);
    // "Anywhere" shows only once it was set from the command line.
    expect(find.text('Anywhere'), findsNothing);
    await h.services.settings.set('security.appSources', 'anywhere');
    await settle(tester);
    expect(find.text('Anywhere'), findsOneWidget);
    await choose(
      tester,
      'security app sources',
      'Flathub and identified developers',
    );
    expect(h.settings.values['security.appSources'], 'trusted');
  });
}
