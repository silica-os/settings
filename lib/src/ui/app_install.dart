// The controls of the Amalfi masters of app installation (docs/design/amalfi/app-installation.md,
// section 5): the App pop-up (`Buttons/Pop-up/App/Regular`) and the Storage App Row.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

// The button's own surface is not exported by silica_ui: the App pop-up draws it so.
// ignore: implementation_imports
import 'package:silica_ui/src/amalfi/components/buttons/button_base.dart';
// ignore: implementation_imports
import 'package:silica_ui/src/amalfi/components/buttons/button_surface.dart';

import '../style.dart';
import '../system/app_install.dart';
import 'symbol.dart';

/// The Regular pop-up with the app icon 16 at x 12 in a 20 slot and the label at x 36
/// (kit `Buttons/Pop-up/App/Regular`). It is `text + 64` wide, rounded up to 4. Its menu lists
/// [apps] with their icons, the current one checked, over the button.
class AppPopUp extends StatefulWidget {
  const AppPopUp({
    super.key,
    required this.apps,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<AppChoice> apps;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  @override
  State<AppPopUp> createState() => _AppPopUpState();
}

class _AppPopUpState extends State<AppPopUp> {
  bool _open = false;

  AppChoice? get _current =>
      widget.apps.where((a) => a.id == widget.value).firstOrNull;

  Future<void> _show(BuildContext context) async {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || widget.apps.isEmpty) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final index = widget.apps.indexWhere((a) => a.id == widget.value);
    const row = 24.0;
    // The checked row over the button, the menu's edge 12 left of it; a pop-up with nothing
    // checked opens at the first row.
    final top =
        rect.top +
        AmalfiPopUpMenuMetrics.rowTopInControl(
          AmalfiPopUpControl.regular,
          rect.height,
        ) -
        AmalfiPopUpMenuMetrics.padding -
        math.max(index, 0) * row;
    final left =
        rect.left -
        AmalfiPopUpMenuMetrics.leftOfControl(AmalfiPopUpControl.regular);
    setState(() => _open = true);
    await showAmalfiMenu(
      context: context,
      position: Offset(left, top),
      minWidth: 188,
      entries: [
        for (final app in widget.apps)
          AmalfiMenuAction(
            app.name,
            checked: app.id == widget.value,
            icon: AmalfiAppIcon(app.icon),
            onSelected: () => widget.onChanged?.call(app.id),
          ),
      ],
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final look = amalfiControlLook(colors);
    const height = 28.0;
    final current = _current;
    final label = current?.name ?? '';
    final enabled = widget.onChanged != null && widget.apps.isNotEmpty;
    return AmalfiButtonBehavior(
      onPressed: enabled ? () => _show(context) : null,
      pressed: _open,
      semanticLabel: widget.semanticLabel == null
          ? label
          : '${widget.semanticLabel}, $label',
      builder: (context, visual) => AmalfiButtonSurface(
        look: look,
        shape: AmalfiSmoothBorder(radius: AmalfiRadii.capsule(height)),
        visual: visual,
        child: SizedBox(
          width: appPopUpWidth(label),
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 6,
                width: 20,
                height: 16,
                child: current == null
                    ? const SizedBox.shrink()
                    : AmalfiAppIcon(current.icon),
              ),
              Positioned(
                left: 36,
                right: 28,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AmalfiPopUpButtonMetrics.labelStyle(
                      AmalfiControlSize.regular,
                      look.content,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 6,
                width: 16,
                height: 16,
                child: AmalfiGlyph(
                  AmalfiGlyphs.chevronUpDown,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of Storage › Applications (kit `Apps/Settings/Storage App Row`, 52 tall): the icon
/// 32 at (12, 10), the name at (56, 9), the kind at (56, 27), the size ending 8 before the
/// remove button (28 × 28 at x 512), or at the card's padding on a System row ([onRemove] null).
class StorageAppRow extends StatelessWidget {
  const StorageAppRow({
    super.key,
    required this.icon,
    required this.name,
    required this.kind,
    required this.size,
    this.onRemove,
    this.removeLabel = '',
  });

  /// The silica-icons id of the app.
  final String icon;
  final String name;
  final String kind;

  /// The formatted size; null while it is measured.
  final String? size;
  final VoidCallback? onRemove;
  final String removeLabel;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final remove = onRemove;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 10,
            width: 32,
            height: 32,
            child: AmalfiAppIcon(icon, size: 32),
          ),
          Positioned(
            left: 56,
            top: 9,
            right: 136,
            height: 18,
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.body(color: colors.text),
            ),
          ),
          Positioned(
            left: 56,
            top: 27,
            right: 136,
            height: 16,
            child: Text(
              kind,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.callout(color: colors.secondary),
            ),
          ),
          Positioned(
            right: remove == null ? 12 : 48,
            top: 17,
            width: 88,
            height: 18,
            child: size == null
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: AmalfiSpinner(size: AmalfiProgressSize.small),
                  )
                : Text(
                    size!,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: AmalfiType.body(color: colors.secondary),
                  ),
          ),
          if (remove != null)
            Positioned(
              right: 12,
              top: 12,
              width: 28,
              height: 28,
              child: Semantics(
                button: true,
                label: removeLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: remove,
                  child: Center(
                    child: SettingsSymbol(
                      'trash',
                      color: colors.secondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
