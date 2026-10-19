// The "…" button at the end of a row and the confirmation alert, on the Amalfi menu and alert
// (kit `Apps/Settings/Row/Network Secure`: the ellipsis glyph, 16 pt, at x 508 of the row).

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../style.dart';
import 'symbol.dart';

/// The "…" button at the end of a row (a network, a device): its menu holds the row's
/// actions.
class MoreButton extends StatelessWidget {
  const MoreButton({
    super.key,
    required this.entries,
    required this.semanticLabel,
  });

  /// Built when the menu opens, so it shows the current state.
  final List<AmalfiMenuEntry> Function() entries;
  final String semanticLabel;

  /// The width of the menu under the button.
  static const double menuWidth = 200;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final box = context.findRenderObject();
            if (box is! RenderBox || !box.hasSize) return;
            // Under the button, the menu's trailing edge on the button's.
            final corner = box.localToGlobal(box.size.bottomRight(Offset.zero));
            showAmalfiMenu(
              context: context,
              position: Offset(corner.dx - menuWidth, corner.dy + 4),
              entries: entries(),
              width: menuWidth,
              opaque: true,
            );
          },
          child: SizedBox.square(
            dimension: 16,
            child: SettingsSymbol(
              'ellipsis',
              color: colors.secondary,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks to confirm a destructive action with the Amalfi alert, centred over the window;
/// true when [confirm] was chosen. Esc and Cancel answer false.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
  bool cancelDefault = false,
}) {
  final overlay = Overlay.of(context);
  final done = Completer<bool>();
  late final OverlayEntry entry;
  void answer(bool value) {
    if (done.isCompleted) return;
    entry.remove();
    done.complete(value);
  }

  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: ColoredBox(
        color: const Color(0x33000000),
        child: Center(
          child: AmalfiAlert(
            key: const ValueKey('confirm'),
            title: title,
            message: message,
            // Cancel is the default (Primary, last) when [cancelDefault]: the confirm button is
            // then a plain Secondary one (kit alert `Quit and Move`).
            actions: cancelDefault
                ? [
                    AmalfiPushButton(
                      label: confirm,
                      onPressed: () => answer(true),
                    ),
                    AmalfiPushButton(
                      label: cancel,
                      variant: AmalfiPushButtonVariant.primary,
                      onPressed: () => answer(false),
                    ),
                  ]
                : [
                    AmalfiPushButton(
                      label: cancel,
                      onPressed: () => answer(false),
                    ),
                    AmalfiPushButton(
                      label: confirm,
                      variant: AmalfiPushButtonVariant.destructive,
                      onPressed: () => answer(true),
                    ),
                  ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}
