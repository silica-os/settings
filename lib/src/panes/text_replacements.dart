// The Text Replacements sheet (Keyboard › Text Input): short texts that become phrases as the
// user types (`omw` → `On my way!`). silica-daemon keeps the list (`SetTextReplacements`) and
// every app's text fields apply it (silica_ui). A row without a shortcut or a phrase, or with
// a shortcut used twice, says so and is not sent.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';

/// How many replacements the daemon keeps.
const int maxReplacements = 500;

/// The part of [rows] the daemon can take: both texts filled in, no spaces in the shortcut,
/// the first of a repeated shortcut.
List<(String, String)> usable(List<(String, String)> rows) {
  final seen = <String>{};
  return [
    for (final (shortcut, phrase) in rows)
      if (shortcut.isNotEmpty &&
          !shortcut.contains(RegExp(r'\s')) &&
          shortcut.runes.length <= 40 &&
          phrase.isNotEmpty &&
          phrase.runes.length <= 1000 &&
          seen.add(shortcut))
        (shortcut, phrase),
  ];
}

Future<void> showTextReplacements(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showAmalfiSheet<void>(
    context,
    semanticLabel: l.keyboardTextReplacements,
    builder: (context, sheet) => _TextReplacementsSheet(close: sheet.close),
  );
}

class _Row {
  _Row(String shortcut, String phrase)
    : shortcut = TextEditingController(text: shortcut),
      phrase = TextEditingController(text: phrase);

  final TextEditingController shortcut;
  final TextEditingController phrase;

  (String, String) get pair => (shortcut.text, phrase.text);

  void dispose() {
    shortcut.dispose();
    phrase.dispose();
  }
}

class _TextReplacementsSheet extends StatefulWidget {
  const _TextReplacementsSheet({required this.close});
  final VoidCallback close;

  @override
  State<_TextReplacementsSheet> createState() => _TextReplacementsSheetState();
}

class _TextReplacementsSheetState extends State<_TextReplacementsSheet> {
  final List<_Row> _rows = [];
  bool _loaded = false;

  /// What the daemon has (or refused): to send only changes.
  List<(String, String)> _sent = const [];
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    ServicesScope.of(context).system.state().then((state) {
      if (!mounted) return;
      setState(() {
        _sent = state.textReplacements;
        _rows.addAll([for (final (s, p) in _sent) _Row(s, p)]);
      });
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final system = ServicesScope.of(context).system;
    final list = usable([for (final row in _rows) row.pair]);
    if (list.length == _sent.length &&
        [
          for (var i = 0; i < list.length; i++) list[i] == _sent[i],
        ].every((e) => e)) {
      return;
    }
    final error = await system.setTextReplacements(list);
    if (!mounted) return;
    setState(() {
      _error = error;
      if (error == null) _sent = list;
    });
  }

  void _add() {
    if (_rows.length >= maxReplacements) return;
    setState(() => _rows.add(_Row('', '')));
  }

  void _remove(_Row row) {
    setState(() {
      _rows.remove(row);
      row.dispose();
    });
    _save();
  }

  /// Why this row is not sent, or null.
  String? _problem(AppLocalizations l, int index) {
    final (shortcut, phrase) = _rows[index].pair;
    if (shortcut.isEmpty && phrase.isEmpty) return null;
    if (shortcut.isEmpty || phrase.isEmpty) return l.replacementsIncomplete;
    if (shortcut.contains(RegExp(r'\s'))) return l.replacementsNoSpaces;
    for (var i = 0; i < index; i++) {
      if (_rows[i].shortcut.text == shortcut) return l.replacementsRepeated;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return SizedBox(
      width: 520,
      height: 420,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.group,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _rows.isEmpty
                    ? Center(
                        child: Text(
                          l.replacementsEmpty,
                          key: const ValueKey('replacements empty'),
                          style: settingsText(13, colors.secondary),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          for (final (i, row) in _rows.indexed)
                            Padding(
                              key: ObjectKey(row),
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AmalfiTextField(
                                        key: ValueKey(
                                          'replacement shortcut $i',
                                        ),
                                        controller: row.shortcut,
                                        placeholder: l.replacementsShortcut,
                                        width: 120,
                                        errorText: _problem(l, i),
                                        onChanged: (_) {
                                          setState(() {});
                                          _save();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AmalfiTextField(
                                          key: ValueKey(
                                            'replacement phrase $i',
                                          ),
                                          controller: row.phrase,
                                          placeholder: l.replacementsPhrase,
                                          width: double.infinity,
                                          onChanged: (_) {
                                            setState(() {});
                                            _save();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AmalfiPushButton(
                                        key: ValueKey('replacement remove $i'),
                                        label: l.keyboardSourceRemove,
                                        size: AmalfiControlSize.small,
                                        onPressed: () => _remove(row),
                                      ),
                                    ],
                                  ),
                                  if (_problem(l, i) case final problem?)
                                    Padding(
                                      key: ValueKey('replacement problem $i'),
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        2,
                                        0,
                                        0,
                                      ),
                                      child: Text(
                                        problem,
                                        style: settingsText(
                                          11,
                                          colors.secondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AmalfiPushButton(
                  key: const ValueKey('replacement add'),
                  label: l.replacementsAdd,
                  size: AmalfiControlSize.small,
                  onPressed: _rows.length >= maxReplacements ? null : _add,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error ?? l.replacementsHelp,
                    key: const ValueKey('replacements note'),
                    style: settingsText(11, colors.secondary, height: 1.3),
                  ),
                ),
                AmalfiPushButton(
                  key: const ValueKey('replacements done'),
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
