// Settings' menus in Silica's menu bar (silica-menu-v1): the app menu, Edit, View, Window and
// Help, as measured (MENU-01). There is no File menu and no Settings item. View holds the
// navigation (back, forward, search) and every pane, the current one checked.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'model/navigation.dart';
import 'model/panes.dart';
import 'model/titles.dart';

/// The menus for the current state: [panes] are the sidebar's panes, [searchFocused] whether
/// the sidebar search field has the keyboard (it enables the text items of Edit) and
/// [hasText] whether it holds text.
List<PlatformMenuItem> settingsMenus(
  AppLocalizations l, {
  required Navigation navigation,
  required List<PaneId> panes,
  required VoidCallback focusSearch,
  required bool searchFocused,
  required bool hasText,
}) {
  const cause = SelectionChangedCause.keyboard;
  SilicaMenuItem text(
    SilicaMenuItemRole role,
    Intent intent,
    SingleActivator? shortcut, {
    required bool enabled,
  }) => SilicaMenuItem(
    role: role,
    shortcut: shortcut,
    onSelectedIntent: enabled ? intent : null,
    enabled: enabled,
  );
  SingleActivator meta(LogicalKeyboardKey key, {bool shift = false}) =>
      SingleActivator(key, meta: true, shift: shift);

  final sorted = [...panes]
    ..sort(
      (a, b) => paneTitle(
        l,
        a,
      ).toLowerCase().compareTo(paneTitle(l, b).toLowerCase()),
    );
  return [
    SilicaMenus.app(
      l.appTitle,
      onAbout: () =>
          navigation.open(const Location(PaneId.general, SubPaneId.about)),
    ),
    SilicaMenu(
      label: l.menuEdit,
      menus: [
        PlatformMenuItemGroup(
          members: [
            text(
              SilicaMenuItemRole.undo,
              const UndoTextIntent(cause),
              meta(LogicalKeyboardKey.keyZ),
              enabled: searchFocused && hasText,
            ),
            text(
              SilicaMenuItemRole.redo,
              const RedoTextIntent(cause),
              meta(LogicalKeyboardKey.keyZ, shift: true),
              enabled: searchFocused && hasText,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            text(
              SilicaMenuItemRole.cut,
              const CopySelectionTextIntent.cut(cause),
              meta(LogicalKeyboardKey.keyX),
              enabled: searchFocused && hasText,
            ),
            text(
              SilicaMenuItemRole.copy,
              CopySelectionTextIntent.copy,
              meta(LogicalKeyboardKey.keyC),
              enabled: searchFocused && hasText,
            ),
            text(
              SilicaMenuItemRole.paste,
              const PasteTextIntent(cause),
              meta(LogicalKeyboardKey.keyV),
              enabled: searchFocused,
            ),
            text(
              SilicaMenuItemRole.delete,
              const DeleteCharacterIntent(forward: true),
              null,
              enabled: searchFocused && hasText,
            ),
            text(
              SilicaMenuItemRole.selectAll,
              const SelectAllTextIntent(cause),
              meta(LogicalKeyboardKey.keyA),
              enabled: searchFocused,
            ),
          ],
        ),
        // Not available yet: shown disabled, as the reference shows unavailable items.
        PlatformMenuItemGroup(
          members: [
            SilicaMenu(
              label: l.menuWritingTools,
              enabled: false,
              menus: const [],
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            SilicaMenu(label: l.menuAutoFill, enabled: false, menus: const []),
            SilicaMenuItem(label: l.menuStartDictation, enabled: false),
            SilicaMenuItem(label: l.menuEmojiSymbols, enabled: false),
          ],
        ),
      ],
    ),
    SilicaMenu(
      label: l.menuView,
      menus: [
        PlatformMenuItemGroup(
          members: [
            SilicaMenuItem(
              label: l.menuBack,
              shortcut: meta(LogicalKeyboardKey.bracketLeft),
              enabled: navigation.canGoBack,
              onSelected: navigation.canGoBack ? navigation.back : null,
            ),
            SilicaMenuItem(
              label: l.menuForward,
              shortcut: meta(LogicalKeyboardKey.bracketRight),
              enabled: navigation.canGoForward,
              onSelected: navigation.canGoForward ? navigation.forward : null,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            SilicaMenuItem(
              label: l.menuSearch,
              shortcut: meta(LogicalKeyboardKey.keyF),
              onSelected: focusSearch,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            for (final pane in sorted)
              SilicaMenuItem(
                label: paneTitle(l, pane),
                checked: pane == navigation.pane,
                onSelected: () => navigation.openPane(pane),
              ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: [
            SilicaMenuItem.system(
              SilicaMenuItemRole.fullScreen,
              enabled: false,
            ),
          ],
        ),
      ],
    ),
    SilicaMenus.window(l.menuWindow, close: true),
    // Help is silica_ui's standard menu (silica-ui#99).
  ];
}
