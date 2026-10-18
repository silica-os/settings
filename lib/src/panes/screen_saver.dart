// The Screen Saver sheet (ST-SSV-01), opened from Wallpaper: which saver the shell draws and
// how long the computer is idle before it starts (screensaver.json, which Ossido watches; the
// shell draws the saver). The lock screen's password delay counts from the moment it starts.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';
import '../system/shell_config.dart';
import '../ui/grouped.dart';

String screenSaverName(AppLocalizations l, String id) => switch (id) {
  'clock' => l.screenSaverClock,
  'colors' => l.screenSaverColors,
  _ => l.screenSaverDrift,
};

Future<void> showScreenSaver(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showAmalfiSheet<void>(
    context,
    semanticLabel: l.wallpaperScreenSaver,
    builder: (context, sheet) => _ScreenSaverSheet(close: sheet.close),
  );
}

class _ScreenSaverSheet extends StatefulWidget {
  const _ScreenSaverSheet({required this.close});
  final VoidCallback close;

  @override
  State<_ScreenSaverSheet> createState() => _ScreenSaverSheetState();
}

class _ScreenSaverSheetState extends State<_ScreenSaverSheet> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    final colors = SettingsColors.of(context);
    final chosen = config.screenSaver();
    final minutes = config.screenSaverAfter();
    String after(int m) => m == 0
        ? l.lockNever
        : m % 60 == 0
        ? l.lockHours(m ~/ 60)
        : l.lockMinutes(m);
    final choices = {...screenSaverMinutes, minutes}.toList()
      ..sort((a, b) => (a == 0 ? 1 << 30 : a).compareTo(b == 0 ? 1 << 30 : b));
    return SizedBox(
      width: 420,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGroup(
              children: [
                ValueRow(
                  title: l.screenSaver,
                  alignTop: true,
                  trailing: SettingsRadioGroup<String>(
                    key: const ValueKey('screen saver'),
                    options: [
                      for (final id in screenSaverChoices)
                        RadioOption(id, screenSaverName(l, id)),
                    ],
                    value: chosen,
                    onChanged: (id) =>
                        setState(() => config.writeScreenSaver(id)),
                  ),
                ),
                PopUpRow<int>(
                  key: const ValueKey('screen saver after'),
                  title: l.screenSaverStartAfter,
                  items: [for (final m in choices) PopUpItem(m, after(m))],
                  value: minutes,
                  onChanged: (m) =>
                      setState(() => config.writeScreenSaverMinutes(m)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.screenSaverHelp,
              style: settingsText(11, colors.secondary, height: 1.3),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AmalfiPushButton(
                key: const ValueKey('screen saver done'),
                label: l.done,
                variant: AmalfiPushButtonVariant.primary,
                onPressed: widget.close,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
