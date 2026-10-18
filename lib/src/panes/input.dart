// Keyboard (ST-KBD-01..14), Mouse and Trackpad (ST-INP-01) and Printers and Scanners (ST-PRT-01).
// Real: the system shortcuts (silica-desktop's command catalog), editable in shortcuts.json,
// which Ossido applies at once; the text replacements (silica-daemon, applied by silica_ui);
// the CUPS printers (lpstat) and the default one (lpoptions). Ossido watches keyboard.json (key
// repeat, input sources, #73) and input.json (the mouse and the touchpad, #74): the sliders,
// switches and the sources sheet write them. The Trackpad pane is in the sidebar only while the
// compositor reports a touchpad. Dictation (#73) and adding printers (#56) wait for their
// backends.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';
import '../system/host.dart';
import '../system/settings_files.dart';
import '../system/shortcuts.dart';
import 'general.dart' show showChoiceSheet;
import 'text_replacements.dart' show showTextReplacements;
import '../model/issues.dart';
import '../ui/grouped.dart';

/// The key repeat rate slider's steps, in repeats per second; 0 turns repeat off. The
/// reference slider has 8 positions and does not expose its rate (ST-KBD-01): the values are
/// ours, provisional.
const List<int> repeatRateSteps = [0, 2, 6, 10, 15, 25, 30, 40];

/// The delay-until-repeat slider's steps, long to short, in ms (6 positions; values ours,
/// provisional).
const List<int> repeatDelaySteps = [1500, 1000, 800, 600, 400, 250];

/// The defaults: the reference machine read step 6 of the rate and step 4 of the delay
/// (1-based), which here are 25 per second and 600 ms.
const int defaultRepeatRate = 25;
const int defaultRepeatDelay = 600;

/// The step closest to [value].
int nearestStep(List<int> steps, int value) {
  var best = 0;
  for (var i = 1; i < steps.length; i++) {
    if ((steps[i] - value).abs() < (steps[best] - value).abs()) best = i;
  }
  return best;
}

class KeyboardPane extends StatefulWidget {
  const KeyboardPane({super.key});

  @override
  State<KeyboardPane> createState() => _KeyboardPaneState();
}

class _KeyboardPaneState extends State<KeyboardPane> {
  Map<String, String> _names = const {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      ServicesScope.of(context).tools.keymapNames().then((names) {
        if (mounted) setState(() => _names = names);
      });
    }
  }

  /// The repeat in effect when keyboard.json has none: `OSSIDO_KEY_REPEAT` (`delay,rate`)
  /// when the session sets it, Ossido's defaults otherwise (375 ms, 11 per second).
  (int, int) _fallback(Map<String, String> env) {
    final parts = (env['OSSIDO_KEY_REPEAT'] ?? '').split(',');
    if (parts.length == 2) {
      final delay = int.tryParse(parts[0].trim());
      final rate = int.tryParse(parts[1].trim());
      if (delay != null && rate != null && delay >= 0 && rate >= 0) {
        return (delay, rate);
      }
    }
    return (KeyboardLimits.delayDefault, KeyboardLimits.rateDefault);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final config = services.config;
    final (fallbackDelay, fallbackRate) = _fallback(services.env);
    final delay = config.savedRepeatDelay ?? fallbackDelay;
    final rate = config.savedRepeatRate ?? fallbackRate;
    final sources = config.savedLayouts;
    return PanePage(
      children: [
        SettingsGroup(
          footer: [l.keyboardRepeatNote, l.notAvailableYet].join(' '),
          children: [
            ValueRow(
              title: l.keyboardRepeatRate,
              height: 56,
              trailing: LabelledSlider(
                key: const ValueKey('repeat rate'),
                value: nearestStep(repeatRateSteps, rate).toDouble(),
                min: 0,
                max: repeatRateSteps.length - 1,
                divisions: repeatRateSteps.length - 1,
                ticks: true,
                labels: [l.keyboardOff, l.keyboardSlow, l.keyboardFast],
                width: 240,
                semanticLabel: l.keyboardRepeatRate,
                onChanged: (v) {
                  config.writeRepeatRate(repeatRateSteps[v.round()]);
                  setState(() {});
                },
              ),
            ),
            ValueRow(
              title: l.keyboardRepeatDelay,
              height: 56,
              trailing: LabelledSlider(
                key: const ValueKey('repeat delay'),
                value: nearestStep(repeatDelaySteps, delay).toDouble(),
                min: 0,
                max: repeatDelaySteps.length - 1,
                divisions: repeatDelaySteps.length - 1,
                ticks: true,
                labels: [l.keyboardLong, l.keyboardShort],
                width: 240,
                semanticLabel: l.keyboardRepeatDelay,
                onChanged: (v) {
                  config.writeRepeatDelay(repeatDelaySteps[v.round()]);
                  setState(() {});
                },
              ),
            ),
            Unavailable(
              child: PopUpRow<int>(
                title: l.keyboardGlobeKey,
                items: [PopUpItem(0, l.keyboardDoNothing)],
                value: 0,
                onChanged: (_) {},
              ),
            ),
            SwitchRow(
              key: const ValueKey('keyboard navigation'),
              title: l.keyboardNavigation,
              subtitle: l.keyboardNavigationHelp,
              value: services.keyboardNavigation.value,
              onChanged: (on) =>
                  setState(() => services.setKeyboardNavigation(on)),
            ),
          ],
        ),
        ButtonBar(
          buttons: [
            AmalfiPushButton(
              key: const ValueKey('shortcuts'),
              label: l.keyboardShortcutsButton,
              size: AmalfiControlSize.small,
              onPressed: () => showShortcuts(context),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.keyboardTextInput,
          footer: l.notAvailableYet,
          children: [
            ButtonRow(
              key: const ValueKey('input sources'),
              title: l.keyboardInputSources,
              subtitle: sources.isEmpty
                  ? l.keyboardSystemDefault
                  : [
                      for (final s in sources) _layoutName(_names, s),
                    ].join(', '),
              label: l.edit,
              onPressed: () async {
                await showInputSources(context, names: _names);
                if (mounted) setState(() {});
              },
            ),
            ButtonRow(
              key: const ValueKey('text replacements'),
              title: l.keyboardTextReplacements,
              label: l.edit,
              onPressed: () => showTextReplacements(context),
            ),
            Unavailable(
              child: SwitchRow(title: l.keyboardDictation, value: false),
            ),
          ],
        ),
      ],
    );
  }
}

/// A layout's readable name (`Italian`), or its code.
String _layoutName(Map<String, String> names, String id) => names[id] ?? id;

/// The input sources sheet: the sources in order (the first is active at start), each with a
/// remove button, and Add… for another layout and its variant (keyboard.json `layouts`).
Future<void> showInputSources(
  BuildContext context, {
  required Map<String, String> names,
}) {
  final l = AppLocalizations.of(context);
  return showAmalfiSheet<void>(
    context,
    semanticLabel: l.keyboardInputSources,
    builder: (context, sheet) =>
        _SourcesSheet(names: names, close: sheet.close),
  );
}

class _SourcesSheet extends StatefulWidget {
  const _SourcesSheet({required this.names, required this.close});
  final Map<String, String> names;
  final VoidCallback close;

  @override
  State<_SourcesSheet> createState() => _SourcesSheetState();
}

class _SourcesSheetState extends State<_SourcesSheet> {
  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final layouts = await services.tools.keymapLayouts();
    if (!mounted || layouts.isEmpty) return;
    final layout = await showChoiceSheet(
      context,
      title: l.keyboardChooseLayout,
      values: layouts,
      current: '',
      label: (v) => _layoutName(widget.names, v),
    );
    if (layout == null || !mounted) return;
    final variants = await services.tools.keymapVariants(layout);
    var variant = '';
    if (variants.isNotEmpty && mounted) {
      // '' stands for the layout's own keys.
      final chosen = await showChoiceSheet(
        context,
        title: l.keyboardChooseVariant,
        values: ['', ...variants],
        current: '',
        label: (v) => v.isEmpty
            ? l.keyboardVariantDefault
            : _layoutName(widget.names, layoutId(layout, v)),
      );
      if (chosen == null || !mounted) return;
      variant = chosen;
    }
    final sources = services.config.savedLayouts;
    final id = layoutId(layout, variant);
    if (sources.contains(id) || sources.length >= KeyboardLimits.maxLayouts) {
      return;
    }
    services.config.writeLayouts([...sources, id]);
    setState(() {});
  }

  void _remove(String id) {
    final config = ServicesScope.of(context).config;
    config.writeLayouts([
      for (final s in config.savedLayouts)
        if (s != id) s,
    ]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final sources = ServicesScope.of(context).config.savedLayouts;
    final full = sources.length >= KeyboardLimits.maxLayouts;
    return SizedBox(
      width: 460,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.keyboardInputSources,
              style: settingsText(13, colors.text, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            GroupBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sources.isEmpty)
                    ValueRow(
                      key: const ValueKey('source default'),
                      title: l.keyboardSystemDefault,
                    )
                  else
                    for (final (i, id) in sources.indexed) ...[
                      if (i > 0) const RowSeparator(),
                      ValueRow(
                        key: ValueKey('source $id'),
                        title: _layoutName(widget.names, id),
                        subtitle: i == 0 ? l.keyboardSourceFirst : null,
                        trailing: AmalfiPushButton(
                          key: ValueKey('remove source $id'),
                          label: l.keyboardSourceRemove,
                          size: AmalfiControlSize.small,
                          onPressed: () => _remove(id),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              full ? l.keyboardSourcesFull : l.keyboardSourcesHelp,
              style: settingsText(11, colors.secondary, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                AmalfiPushButton(
                  key: const ValueKey('add source'),
                  label: l.addButton,
                  size: AmalfiControlSize.small,
                  onPressed: full ? null : _add,
                ),
                const Spacer(),
                AmalfiPushButton(
                  key: const ValueKey('sources done'),
                  label: l.done,
                  variant: AmalfiPushButtonVariant.primary,
                  onPressed: widget.close,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A system shortcut: the catalog command [id] (silica-desktop's command catalog), its action
/// and the keys it has by default (the catalog's format; null: none). Logo is the key with the
/// system logo.
class SystemShortcut {
  const SystemShortcut(this.id, this.action, this.defaultKeys);
  final String id;
  final String action;
  final String? defaultKeys;
}

/// Silica's system shortcuts by category.
List<(String, List<SystemShortcut>)> systemShortcuts(AppLocalizations l) => [
  (
    l.shortcutsScreenshots,
    [
      SystemShortcut('screenshot.screen', l.shortcutScreen, 'Logo+Shift+3'),
      SystemShortcut(
        'screenshot.screen_clipboard',
        l.shortcutScreenClipboard,
        'Logo+Ctrl+Shift+3',
      ),
      SystemShortcut(
        'screenshot.selection',
        l.shortcutSelection,
        'Logo+Shift+4',
      ),
      SystemShortcut(
        'screenshot.selection_clipboard',
        l.shortcutSelectionClipboard,
        'Logo+Ctrl+Shift+4',
      ),
      SystemShortcut('screenshot.toolbar', l.shortcutTools, 'Logo+Shift+5'),
    ],
  ),
  (
    l.shortcutsSpaces,
    [
      SystemShortcut('panorama.toggle', l.shortcutPanorama, 'Ctrl+Up'),
      SystemShortcut('panorama.app', l.shortcutAppWindows, 'Ctrl+Down'),
      SystemShortcut('desktop.show', l.shortcutShowDesktop, 'F11'),
      SystemShortcut('space.previous', l.shortcutPreviousSpace, 'Ctrl+Left'),
      SystemShortcut('space.next', l.shortcutNextSpace, 'Ctrl+Right'),
    ],
  ),
  (
    l.shortcutsApps,
    [
      SystemShortcut('faro.toggle', l.shortcutSearch, 'Logo+space'),
      SystemShortcut('launcher.toggle', l.shortcutLauncher, null),
      SystemShortcut('notifications.toggle', l.shortcutNotifications, null),
      SystemShortcut('controlcenter.toggle', l.shortcutControlCenter, null),
      SystemShortcut('switcher.next', l.shortcutNextApp, 'Logo+Tab'),
      SystemShortcut(
        'switcher.previous',
        l.shortcutPreviousApp,
        'Logo+Shift+Tab',
      ),
      SystemShortcut('app.quit', l.shortcutQuitApp, 'Logo+Q'),
      SystemShortcut('app.hide', l.shortcutHideApp, 'Logo+H'),
      SystemShortcut('app.hide_others', l.shortcutHideOthers, 'Logo+Alt+H'),
      SystemShortcut(
        'app.force_quit_panel',
        l.shortcutForceQuit,
        'Logo+Alt+Escape',
      ),
    ],
  ),
  (
    l.shortcutsWindows,
    [
      SystemShortcut('window.close', l.shortcutCloseWindow, 'Logo+W'),
      SystemShortcut('window.minimize', l.shortcutMinimize, 'Logo+M'),
      SystemShortcut('window.fullscreen', l.shortcutFullScreen, 'Logo+Ctrl+F'),
      SystemShortcut('window.tile_fill', l.shortcutFill, null),
      SystemShortcut('window.tile_left', l.shortcutLeftHalf, 'Logo+Ctrl+Left'),
      SystemShortcut(
        'window.tile_right',
        l.shortcutRightHalf,
        'Logo+Ctrl+Right',
      ),
      SystemShortcut('window.tile_top', l.shortcutTopHalf, 'Logo+Ctrl+Up'),
      SystemShortcut(
        'window.tile_bottom',
        l.shortcutBottomHalf,
        'Logo+Ctrl+Down',
      ),
    ],
  ),
  (
    l.shortcutsInputSources,
    [
      SystemShortcut(
        'keyboard.next_source',
        l.shortcutNextSource,
        'Ctrl+space',
      ),
    ],
  ),
  (
    l.shortcutsSession,
    [SystemShortcut('session.quit', l.shortcutLogOut, 'Logo+Shift+Q')],
  ),
];

/// The keyboard shortcuts sheet: categories on the left, the shortcuts on the right. The
/// checkbox switches a shortcut on or off; a click on its keys records a new combination
/// (shortcuts.json, which Ossido applies at once).
Future<void> showShortcuts(BuildContext context) {
  final l = AppLocalizations.of(context);
  final categories = systemShortcuts(l);
  final bindings = ShortcutBindings(ServicesScope.of(context).config);
  return showAmalfiSheet<void>(
    context,
    semanticLabel: l.keyboardShortcutsButton,
    builder: (context, sheet) => _ShortcutsSheet(
      categories: categories,
      bindings: bindings,
      close: sheet.close,
    ),
  );
}

class _ShortcutsSheet extends StatefulWidget {
  const _ShortcutsSheet({
    required this.categories,
    required this.bindings,
    required this.close,
  });
  final List<(String, List<SystemShortcut>)> categories;
  final ShortcutBindings bindings;
  final VoidCallback close;

  @override
  State<_ShortcutsSheet> createState() => _ShortcutsSheetState();
}

class _ShortcutsSheetState extends State<_ShortcutsSheet> {
  int _selected = 0;

  /// The shortcut whose keys are being recorded.
  String? _recording;

  /// A refused combination: what to tell.
  String? _refused;
  final FocusNode _focus = FocusNode(debugLabel: 'record shortcut');

  @override
  void initState() {
    super.initState();
    // A recording left on by a Settings that was closed meanwhile.
    widget.bindings.capture(false);
  }

  @override
  void dispose() {
    widget.bindings.capture(false);
    _focus.dispose();
    super.dispose();
  }

  Iterable<SystemShortcut> get _all => widget.categories.expand((c) => c.$2);

  KeyCombo? _keysOf(SystemShortcut s) =>
      widget.bindings.keys(s.id, s.defaultKeys);

  void _record(SystemShortcut s) {
    setState(() {
      _recording = s.id;
      _refused = null;
    });
    widget.bindings.capture(true);
    _focus.requestFocus();
  }

  void _stopRecording() {
    widget.bindings.capture(false);
    if (mounted) setState(() => _recording = null);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final id = _recording;
    if (id == null || event is! KeyDownEvent) return KeyEventResult.ignored;
    final l = AppLocalizations.of(context);
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        !keyboard.isMetaPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isAltPressed) {
      _stopRecording();
      return KeyEventResult.handled;
    }
    final combo = comboOfPress(
      event.logicalKey,
      logo: keyboard.isMetaPressed,
      ctrl: keyboard.isControlPressed,
      alt: keyboard.isAltPressed,
      shift: keyboard.isShiftPressed,
    );
    // A modifier alone: wait for the key.
    if (combo == null) return KeyEventResult.handled;
    if (!combo.isUsable) {
      setState(() => _refused = l.shortcutNeedsModifier);
      return KeyEventResult.handled;
    }
    final other = _all
        .where((s) => s.id != id && _keysOf(s) == combo)
        .firstOrNull;
    if (other != null) {
      setState(() => _refused = l.shortcutInUse(other.action));
      return KeyEventResult.handled;
    }
    widget.bindings.set(id, combo);
    widget.bindings.capture(false);
    setState(() {
      _recording = null;
      _refused = null;
    });
    return KeyEventResult.handled;
  }

  void _toggle(SystemShortcut s, bool on) {
    if (on) {
      widget.bindings.reset(s.id);
    } else {
      widget.bindings.switchOff(s.id);
    }
    setState(() {});
  }

  void _restoreDefaults() {
    for (final s in widget.categories[_selected].$2) {
      widget.bindings.reset(s.id);
    }
    setState(() => _refused = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    final (_, shortcuts) = widget.categories[_selected];
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: SizedBox(
        width: 680,
        height: 420,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 200,
                      child: ListView(
                        children: [
                          for (final (i, (name, _))
                              in widget.categories.indexed)
                            GestureDetector(
                              key: ValueKey('shortcut category $i'),
                              onTap: () {
                                _stopRecording();
                                setState(() => _selected = i);
                              },
                              child: Container(
                                height: 28,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _selected ? accent : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  name,
                                  style: settingsText(
                                    13,
                                    i == _selected
                                        ? const Color(0xFFFFFFFF)
                                        : colors.text,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.group,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView(
                          children: [
                            for (final s in shortcuts) _row(l, colors, s),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _refused ?? l.shortcutsHelp,
                      key: const ValueKey('shortcuts note'),
                      style: settingsText(11, colors.secondary),
                    ),
                  ),
                  AmalfiPushButton(
                    key: const ValueKey('shortcuts restore'),
                    label: l.shortcutsRestoreDefaults,
                    onPressed: _restoreDefaults,
                  ),
                  const SizedBox(width: 8),
                  AmalfiPushButton(
                    key: const ValueKey('shortcuts done'),
                    label: l.done,
                    variant: AmalfiPushButtonVariant.primary,
                    onPressed: widget.close,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppLocalizations l, SettingsColors colors, SystemShortcut s) {
    final keys = _keysOf(s);
    final recording = _recording == s.id;
    return ValueRow(
      key: ValueKey('shortcut ${s.id}'),
      title: s.action,
      leading: AmalfiCheckbox(
        key: ValueKey('shortcut on ${s.id}'),
        value: keys != null,
        semanticLabel: s.action,
        // Without keys there is nothing to switch on: record some first.
        onChanged: keys == null && s.defaultKeys == null
            ? null
            : (on) => _toggle(s, on),
      ),
      trailing: AmalfiPushButton(
        key: ValueKey('shortcut keys ${s.id}'),
        label: recording
            ? l.shortcutRecording
            : keys?.display ?? l.shortcutNone,
        size: AmalfiControlSize.small,
        onPressed: () => recording ? _stopRecording() : _record(s),
      ),
    );
  }
}

/// The scrolling-speed slider position (0–1) of a multiplier: logarithmic, 0.1× to 10×, with
/// 1× in the middle.
double scrollSliderOf(double speed) =>
    (math.log(speed.clamp(PointerLimits.scrollMin, PointerLimits.scrollMax)) /
            math.ln10 +
        1) /
    2;

/// The multiplier of a slider position, to two decimals.
double scrollSpeedOf(double position) => double.parse(
  math.pow(10, position.clamp(0, 1) * 2 - 1).toDouble().toStringAsFixed(2),
);

/// The pointer settings both devices share: speed and natural scrolling (input.json, which
/// Ossido watches and applies to every device at once, #74).
List<Widget> _commonPointerRows(
  BuildContext context,
  PointerDevice device,
  VoidCallback changed,
) {
  final l = AppLocalizations.of(context);
  final config = ServicesScope.of(context).config;
  return [
    SliderRow(
      key: ValueKey('${device.name} speed'),
      title: device == PointerDevice.mouse
          ? l.mousePointerSpeed
          : l.trackpadTrackingSpeed,
      value: config.pointerSpeed(device),
      min: PointerLimits.speedMin,
      max: PointerLimits.speedMax,
      labels: [l.keyboardSlow, l.keyboardFast],
      onChanged: (v) {
        config.writePointerSpeed(device, v);
        changed();
      },
    ),
    SwitchRow(
      key: ValueKey('${device.name} natural scrolling'),
      title: l.mouseNaturalScrolling,
      subtitle: l.mouseNaturalScrollingHelp,
      value: config.pointerFlag(device, 'naturalScroll', fallback: false),
      onChanged: (on) {
        config.writePointer(device, 'naturalScroll', on);
        changed();
      },
    ),
  ];
}

Widget _scrollSpeedRow(
  BuildContext context,
  PointerDevice device,
  VoidCallback changed,
) {
  final l = AppLocalizations.of(context);
  final config = ServicesScope.of(context).config;
  return SliderRow(
    key: ValueKey('${device.name} scroll speed'),
    title: l.mouseScrollSpeed,
    value: scrollSliderOf(config.pointerScrollSpeed(device)),
    labels: [l.keyboardSlow, l.keyboardFast],
    onChanged: (v) {
      config.writeScrollSpeed(device, scrollSpeedOf(v));
      changed();
    },
  );
}

class MousePane extends StatefulWidget {
  const MousePane({super.key});

  @override
  State<MousePane> createState() => _MousePaneState();
}

class _MousePaneState extends State<MousePane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final config = services.config;
    void changed() => setState(() {});
    final secondary = MouseSecondary.values
        .where(
          (v) =>
              v.name ==
              config.pointerText(
                PointerDevice.mouse,
                'secondaryClick',
                fallback: 'right',
              ),
        )
        .firstOrNull;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ..._commonPointerRows(context, PointerDevice.mouse, changed),
            PopUpRow<MouseSecondary>(
              key: const ValueKey('mouse secondary click'),
              title: l.mouseSecondaryClick,
              subtitle: l.mouseSecondaryHelp,
              items: [
                PopUpItem(MouseSecondary.right, l.mouseRightButton),
                PopUpItem(MouseSecondary.left, l.mouseLeftButton),
              ],
              value: secondary ?? MouseSecondary.right,
              onChanged: (v) {
                config.writePointer(
                  PointerDevice.mouse,
                  'secondaryClick',
                  v.name,
                );
                changed();
              },
            ),
            _scrollSpeedRow(context, PointerDevice.mouse, changed),
          ],
        ),
        SettingsGroup(
          footer: l.mouseDoubleClickHelp,
          children: [
            SliderRow(
              key: const ValueKey('double click speed'),
              title: l.mouseDoubleClickSpeed,
              // Slow on the left (the longest time between the clicks), fast on the right.
              value:
                  (Services.doubleClickSlowest - services.doubleClickMs.value) /
                  (Services.doubleClickSlowest - Services.doubleClickFastest),
              labels: [l.keyboardSlow, l.keyboardFast],
              onChanged: (v) => setState(
                () => services.setDoubleClickMs(
                  (Services.doubleClickSlowest -
                          v.clamp(0.0, 1.0) *
                              (Services.doubleClickSlowest -
                                  Services.doubleClickFastest))
                      .round(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrackpadPane extends StatefulWidget {
  const TrackpadPane({super.key});

  @override
  State<TrackpadPane> createState() => _TrackpadPaneState();
}

class _TrackpadPaneState extends State<TrackpadPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    void changed() => setState(() {});
    final secondary = TouchpadSecondary.values
        .where(
          (v) =>
              v.name ==
              config.pointerText(
                PointerDevice.touchpad,
                'secondaryClick',
                fallback: 'twoFinger',
              ),
        )
        .firstOrNull;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ..._commonPointerRows(context, PointerDevice.touchpad, changed),
            SwitchRow(
              key: const ValueKey('touchpad tap to click'),
              title: l.trackpadTapToClick,
              subtitle: l.trackpadTapToClickHelp,
              value: config.pointerFlag(
                PointerDevice.touchpad,
                'tapToClick',
                fallback: false,
              ),
              onChanged: (on) {
                config.writePointer(PointerDevice.touchpad, 'tapToClick', on);
                changed();
              },
            ),
            PopUpRow<TouchpadSecondary>(
              key: const ValueKey('touchpad secondary click'),
              title: l.trackpadSecondaryClick,
              items: [
                PopUpItem(TouchpadSecondary.twoFinger, l.trackpadTwoFingers),
                PopUpItem(TouchpadSecondary.bottomRight, l.trackpadBottomRight),
                PopUpItem(TouchpadSecondary.bottomLeft, l.trackpadBottomLeft),
              ],
              value: secondary ?? TouchpadSecondary.twoFinger,
              onChanged: (v) {
                config.writePointer(
                  PointerDevice.touchpad,
                  'secondaryClick',
                  v.name,
                );
                changed();
              },
            ),
            SwitchRow(
              key: const ValueKey('touchpad disable while typing'),
              title: l.trackpadDisableWhileTyping,
              subtitle: l.trackpadDisableWhileTypingHelp,
              value: config.pointerFlag(
                PointerDevice.touchpad,
                'disableWhileTyping',
                fallback: true,
              ),
              onChanged: (on) {
                config.writePointer(
                  PointerDevice.touchpad,
                  'disableWhileTyping',
                  on,
                );
                changed();
              },
            ),
            _scrollSpeedRow(context, PointerDevice.touchpad, changed),
          ],
        ),
      ],
    );
  }
}

class PrintersPane extends StatefulWidget {
  const PrintersPane({super.key});

  @override
  State<PrintersPane> createState() => _PrintersPaneState();
}

class _PrintersPaneState extends State<PrintersPane> {
  Future<List<Printer>>? _printers;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _printers ??= ServicesScope.of(context).host.printers();
  }

  /// Makes [name] the user's default printer (`lpoptions -d`, no administrator needed).
  Future<void> _setDefault(String name) async {
    final host = ServicesScope.of(context).host;
    final out = await host.run('lpoptions', ['-d', name]);
    if (!mounted) return;
    setState(() {
      _error = out == null
          ? AppLocalizations.of(context).printersDefaultFailed
          : null;
      _printers = host.printers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<Printer>>(
      future: _printers,
      builder: (context, snapshot) {
        final printers = snapshot.data ?? const <Printer>[];
        return PanePage(
          children: [
            SettingsGroup(
              children: [
                PopUpRow<String>(
                  key: const ValueKey('default printer'),
                  title: l.printersDefault,
                  items: [for (final p in printers) PopUpItem(p.name, p.name)],
                  value: printers.where((p) => p.isDefault).firstOrNull?.name,
                  onChanged: printers.isEmpty ? null : _setDefault,
                ),
                Unavailable(
                  child: PopUpRow<int>(
                    title: l.printersPaperSize,
                    items: const [PopUpItem(0, 'A4')],
                    value: 0,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            if (_error case final error?) ErrorLine(error),
            SettingsGroup(
              children: [
                if (printers.isEmpty)
                  EmptyState(l.printersNone)
                else
                  for (final p in printers)
                    ValueRow(
                      key: ValueKey('printer ${p.name}'),
                      title: p.name,
                      subtitle: p.isDefault ? l.printersIsDefault : null,
                    ),
              ],
            ),
            SettingsGroup(
              unavailable: true,
              issue: Issues.printers,
              children: [ButtonRow(title: l.printersAdd, label: l.addButton)],
            ),
          ],
        );
      },
    );
  }
}
