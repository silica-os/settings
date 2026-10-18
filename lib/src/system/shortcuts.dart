// The system keyboard shortcuts (Keyboard › Keyboard Shortcuts): a key combination for a
// command of silica-desktop's catalog, in `shortcuts.json`, which Ossido watches and applies at
// once (docs/control.md › shortcuts.json). A command listed there with a text gets those keys,
// with `null` it has none, and a command left out keeps the catalog's default.

import 'package:flutter/services.dart';

import 'config.dart';

/// A key combination in the catalog's format: `Logo+Shift+Q`, the modifiers (Logo, Ctrl, Alt,
/// Shift) and the xkb name of the key.
class KeyCombo {
  const KeyCombo({
    this.logo = false,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    required this.key,
  });

  final bool logo;
  final bool ctrl;
  final bool alt;
  final bool shift;

  /// The xkb keysym name without modifiers, as Ossido compares it (case-insensitively).
  final String key;

  /// Reads `Logo+Shift+Q`; null when it is not a combination.
  static KeyCombo? parse(String text) {
    final parts = text.split('+').map((p) => p.trim()).toList();
    if (parts.isEmpty || parts.last.isEmpty) return null;
    var logo = false, ctrl = false, alt = false, shift = false;
    for (final part in parts.take(parts.length - 1)) {
      switch (part.toLowerCase()) {
        case 'logo' || 'super':
          logo = true;
        case 'ctrl' || 'control':
          ctrl = true;
        case 'alt':
          alt = true;
        case 'shift':
          shift = true;
        default:
          return null;
      }
    }
    return KeyCombo(
      logo: logo,
      ctrl: ctrl,
      alt: alt,
      shift: shift,
      key: parts.last,
    );
  }

  /// The text in the catalog's format.
  String get text => [
    if (logo) 'Logo',
    if (ctrl) 'Ctrl',
    if (alt) 'Alt',
    if (shift) 'Shift',
    key,
  ].join('+');

  /// The combination as people read it: `Logo ⇧ 3`.
  String get display {
    final shown = switch (key.toLowerCase()) {
      'space' => 'Space',
      'tab' => '⇥',
      'escape' => 'Esc',
      'return' => '↩',
      'backspace' => '⌫',
      'left' => '←',
      'right' => '→',
      'up' => '↑',
      'down' => '↓',
      'comma' => ',',
      'period' => '.',
      'minus' => '-',
      'equal' => '=',
      'slash' => '/',
      'backslash' => '\\',
      'semicolon' => ';',
      'apostrophe' => "'",
      'bracketleft' => '[',
      'bracketright' => ']',
      final other when other.length == 1 => other.toUpperCase(),
      _ => key,
    };
    return [
      if (logo) 'Logo',
      if (ctrl) '⌃',
      if (alt) '⌥',
      if (shift) '⇧',
      shown,
    ].join(' ');
  }

  /// Whether pressing this alone makes sense: a modifier is held, or it is a function key.
  bool get isUsable =>
      logo ||
      ctrl ||
      alt ||
      RegExp(r'^F([1-9]|1\d|2[0-4])$').hasMatch(key) ||
      key.startsWith('XF86');

  @override
  bool operator ==(Object other) =>
      other is KeyCombo &&
      other.logo == logo &&
      other.ctrl == ctrl &&
      other.alt == alt &&
      other.shift == shift &&
      other.key.toLowerCase() == key.toLowerCase();

  @override
  int get hashCode => Object.hash(logo, ctrl, alt, shift, key.toLowerCase());
}

/// The xkb name of a key as Ossido sees it (the symbol of the key without Shift); null for the
/// modifiers and for keys that cannot be bound.
String? keysymOf(LogicalKeyboardKey key) {
  final byKey = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.space: 'space',
    LogicalKeyboardKey.tab: 'Tab',
    LogicalKeyboardKey.escape: 'Escape',
    LogicalKeyboardKey.enter: 'Return',
    LogicalKeyboardKey.backspace: 'BackSpace',
    LogicalKeyboardKey.delete: 'Delete',
    LogicalKeyboardKey.insert: 'Insert',
    LogicalKeyboardKey.home: 'Home',
    LogicalKeyboardKey.end: 'End',
    LogicalKeyboardKey.pageUp: 'Prior',
    LogicalKeyboardKey.pageDown: 'Next',
    LogicalKeyboardKey.arrowLeft: 'Left',
    LogicalKeyboardKey.arrowRight: 'Right',
    LogicalKeyboardKey.arrowUp: 'Up',
    LogicalKeyboardKey.arrowDown: 'Down',
    LogicalKeyboardKey.comma: 'comma',
    LogicalKeyboardKey.period: 'period',
    LogicalKeyboardKey.minus: 'minus',
    LogicalKeyboardKey.equal: 'equal',
    LogicalKeyboardKey.slash: 'slash',
    LogicalKeyboardKey.backslash: 'backslash',
    LogicalKeyboardKey.semicolon: 'semicolon',
    LogicalKeyboardKey.quote: 'apostrophe',
    LogicalKeyboardKey.bracketLeft: 'bracketleft',
    LogicalKeyboardKey.bracketRight: 'bracketright',
  };
  final found = byKey[key];
  if (found != null) return found;
  final label = key.keyLabel;
  if (RegExp(r'^F([1-9]|1\d|2[0-4])$').hasMatch(label)) return label;
  if (label.length == 1 && RegExp(r'^[A-Za-z0-9]$').hasMatch(label)) {
    return label.toLowerCase();
  }
  return null;
}

/// The combination for a key press with the modifiers now held; null for a modifier alone or a
/// key that cannot be bound.
KeyCombo? comboOfPress(
  LogicalKeyboardKey key, {
  required bool logo,
  required bool ctrl,
  required bool alt,
  required bool shift,
}) {
  final name = keysymOf(key);
  if (name == null) return null;
  return KeyCombo(logo: logo, ctrl: ctrl, alt: alt, shift: shift, key: name);
}

/// The reading and writing of `shortcuts.json`.
class ShortcutBindings {
  ShortcutBindings(this.config);

  final ConfigStore config;

  static const file = 'shortcuts';

  /// The keys of [id] now: the user's, none (switched off) or the catalog's [fallback].
  KeyCombo? keys(String id, String? fallback) {
    final all = config.read(file);
    if (all.containsKey(id)) {
      final v = all[id];
      if (v is String) {
        final combo = KeyCombo.parse(v);
        if (combo != null) return combo;
      } else if (v == null) {
        return null;
      }
    }
    return fallback == null ? null : KeyCombo.parse(fallback);
  }

  /// Gives [id] these keys.
  bool set(String id, KeyCombo combo) => config.write(file, id, combo.text);

  /// Switches the shortcut of [id] off (an explicit `null`, so the default does not return).
  bool switchOff(String id) {
    final all = config.read(file);
    all[id] = null;
    return config.replace(file, all);
  }

  /// Back to the catalog's default.
  bool reset(String id) => config.write(file, id, null);

  /// Ossido lets every key reach Settings while a new combination is recorded.
  void capture(bool on) => config.write(file, 'capture', on ? true : null);
}
