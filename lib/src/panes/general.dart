// General (ST-GEN-01..03): the header card and the navigation rows to its sub-panes. About shows
// the real machine (model, processor, graphics, memory, firmware, the system, the displays and
// the disk). Storage measures the home folders and empties the trash. Sharing renames the
// computer (hostnamectl). Date & Time sets the time zone and automatic time (timedatectl).
// Language & Region sets the system language and formats (localectl). Changing them asks
// polkit: the controls are enabled only while silica-daemon's authentication agent is
// registered (`Authentication1.Registered`, #69), which shows the system password dialog;
// without it they are disabled and the pane says why.
// Software update, file and screen sharing, login items, backups and reset wait for their
// backends (#77). The reference's warranty, device management and password autofill rows
// belong to its own services and are left out.

import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/host.dart';
import '../system/shell_config.dart';
import '../system/tools.dart';
import '../system/tools_host.dart';
import '../ui/errors.dart';
import '../ui/grouped.dart';
import '../ui/popup.dart';
import '../ui/symbol.dart';
import 'storage_apps.dart';
import 'security.dart'
    show
        AccessibilityDisplayPane,
        AccessibilityLargerTextPane,
        AccessibilityMotionPane;

/// Bytes in decimal units, as storage is sold ("512 GB").
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

class GeneralPane extends StatelessWidget {
  const GeneralPane({super.key, required this.open});

  final ValueChanged<SubPaneId> open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    NavRow row(SubPaneId sub, String title, String symbol, Color tint) =>
        NavRow(
          key: ValueKey('general ${sub.name}'),
          title: title,
          symbol: symbol,
          tint: tint,
          onTap: () => open(sub),
        );
    const gray = Color(0xFF9A9EA6);
    const blue = Color(0xFF0E77E6);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.general.symbol,
          tint: PaneId.general.tint,
          title: l.paneGeneral,
          description: l.generalDescription,
          centered: true,
        ),
        SettingsGroup(
          children: [
            row(SubPaneId.about, l.subAbout, 'laptop', gray),
            row(
              SubPaneId.softwareUpdate,
              l.subSoftwareUpdate,
              'arrow-clockwise',
              gray,
            ),
            row(SubPaneId.storage, l.subStorage, 'drive', gray),
          ],
        ),
        SettingsGroup(
          children: [row(SubPaneId.sharing, l.subSharing, 'share', gray)],
        ),
        SettingsGroup(
          children: [
            row(SubPaneId.dateTime, l.subDateTime, 'calendar', blue),
            row(SubPaneId.startupDisk, l.subStartupDisk, 'drive', gray),
            row(SubPaneId.loginItems, l.subLoginItems, 'list-bullet', gray),
            row(SubPaneId.languageRegion, l.subLanguageRegion, 'globe', blue),
            row(SubPaneId.backups, l.subBackups, 'history', gray),
          ],
        ),
        SettingsGroup(
          children: [
            row(
              SubPaneId.transferReset,
              l.subTransferReset,
              'arrow-counterclockwise',
              gray,
            ),
          ],
        ),
      ],
    );
  }
}

/// A sub-pane of General.
Widget generalSubPane(SubPaneId sub) => switch (sub) {
  SubPaneId.about => const AboutPane(),
  SubPaneId.storage => const StoragePane(),
  SubPaneId.sharing => const SharingPane(),
  SubPaneId.dateTime => const DateTimePane(),
  SubPaneId.languageRegion => const LanguagePane(),
  SubPaneId.softwareUpdate => const _SoftwareUpdatePane(),
  SubPaneId.accessibilityDisplay => const AccessibilityDisplayPane(),
  SubPaneId.accessibilityMotion => const AccessibilityMotionPane(),
  SubPaneId.accessibilityLargerText => const AccessibilityLargerTextPane(),
  SubPaneId.startupDisk ||
  SubPaneId.loginItems ||
  SubPaneId.backups ||
  SubPaneId.transferReset ||
  SubPaneId.notificationApp => const _UnavailableSubPane(),
};

/// General › About (ST-GEN-02): the computer's picture and model, the specification group,
/// the system, the displays and the disk.
class AboutPane extends StatefulWidget {
  const AboutPane({super.key});

  @override
  State<AboutPane> createState() => _AboutPaneState();
}

class _AboutPaneState extends State<AboutPane> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The graphics adapters (pci.ids) are named only when About is open, once.
    ServicesScope.of(context).loadGraphics();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = HostInfoScope.of(context);
    final colors = SettingsColors.of(context);
    final model = [
      info.vendor,
      info.model,
    ].where((s) => s.isNotEmpty).join(' ');
    final displays = PlatformDispatcher.instance.displays.toList();
    String unknown(String s) => s.isEmpty ? l.aboutUnknown : s;
    return PanePage(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 4),
          child: Column(
            children: [
              SettingsSymbol('laptop', color: colors.secondary, size: 64),
              const SizedBox(height: 18),
              Text(
                model.isEmpty ? l.aboutThisComputer : model,
                key: const ValueKey('about model'),
                textAlign: TextAlign.center,
                style: settingsText(22, colors.text, weight: FontWeight.w700),
              ),
              if (info.firmware.isNotEmpty)
                Text(
                  l.aboutFirmware(info.firmware),
                  style: settingsText(11, colors.secondary),
                ),
            ],
          ),
        ),
        SettingsGroup(
          children: [
            ValueRow(
              title: l.aboutName,
              trailing: RowValue(unknown(info.hostname)),
            ),
            ValueRow(
              title: l.aboutProcessor,
              trailing: RowValue(
                info.cpu.isEmpty
                    ? l.aboutUnknown
                    : info.cpuCount > 1
                    ? l.aboutProcessorCount(info.cpu, info.cpuCount)
                    : info.cpu,
              ),
            ),
            if (info.graphics.isNotEmpty)
              ValueRow(
                key: const ValueKey('about graphics'),
                title: l.aboutGraphics,
                trailing: RowValue(info.graphics.join('\n')),
              ),
            ValueRow(
              title: l.aboutMemory,
              trailing: RowValue(
                info.memoryBytes == 0
                    ? l.aboutUnknown
                    : formatBytes(info.memoryBytes),
              ),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.aboutSoftware,
          children: [
            ValueRow(
              title: unknown(info.osName),
              leading: const IconTile(
                symbol: 'sparkles',
                tint: Color(0xFF8B5CF6),
                size: 28,
              ),
              trailing: RowValue(
                info.osVersion.isEmpty
                    ? l.aboutUnknown
                    : l.aboutVersion(info.osVersion),
              ),
            ),
            ValueRow(
              title: l.aboutKernel,
              trailing: RowValue(unknown(info.kernel)),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.aboutDisplays,
          children: [
            if (displays.isEmpty)
              ValueRow(title: l.aboutUnknown)
            else
              for (final (i, d) in displays.indexed)
                ValueRow(
                  title: l.aboutDisplayN(i + 1),
                  leading: SettingsSymbol(
                    'display',
                    color: colors.secondary,
                    size: 24,
                  ),
                  trailing: RowValue(
                    '${d.size.width.round()} × ${d.size.height.round()}'
                    '${d.refreshRate > 0 ? ' · ${d.refreshRate.round()} Hz' : ''}',
                  ),
                ),
          ],
        ),
        const _DiskGroup(),
      ],
    );
  }
}

/// The system disk: a usage bar and the free space (df).
class _DiskGroup extends StatefulWidget {
  const _DiskGroup();

  @override
  State<_DiskGroup> createState() => _DiskGroupState();
}

class _DiskGroupState extends State<_DiskGroup> {
  Future<DiskUsage?>? _disk;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disk ??= ServicesScope.of(context).host.disk();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<DiskUsage?>(
      future: _disk,
      builder: (context, snapshot) {
        final disk = snapshot.data;
        return SettingsGroup(
          heading: l.subStorage,
          children: [
            if (disk == null)
              ValueRow(
                title: snapshot.connectionState == ConnectionState.done
                    ? l.aboutUnknown
                    : l.storageCalculating,
              )
            else
              ValueRow(
                key: const ValueKey('disk'),
                title: l.storageSystemDisk,
                subtitle: l.storageAvailableOf(
                  formatBytes(disk.available),
                  formatBytes(disk.total),
                ),
                leading: SettingsSymbol(
                  'drive',
                  color: SettingsColors.of(context).secondary,
                  size: 24,
                ),
                trailing: SizedBox(
                  width: 200,
                  child: AmalfiProgressBar(
                    value: disk.total == 0 ? 0 : disk.used / disk.total,
                    semanticLabel: l.subStorage,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// General › Storage: the disk, then what the home folders and the trash take, with Empty
/// Trash.
class StoragePane extends StatefulWidget {
  const StoragePane({super.key});

  @override
  State<StoragePane> createState() => _StoragePaneState();
}

class _StoragePaneState extends State<StoragePane> {
  final Map<String, int?> _sizes = {};
  bool _started = false;
  String? _trashError;

  List<(String, String, String)> _folders(AppLocalizations l) {
    final env = ServicesScope.of(context).env;
    final home = env['HOME'] ?? '';
    final dirs = xdgUserDirs(env);
    return [
      (l.storageDocuments, 'doc-text', dirs['DOCUMENTS'] ?? '$home/Documents'),
      (l.storageDownloads, 'download', dirs['DOWNLOAD'] ?? '$home/Downloads'),
      (l.storagePictures, 'photo', dirs['PICTURES'] ?? '$home/Pictures'),
      (l.storageMusic, 'music-note', dirs['MUSIC'] ?? '$home/Music'),
      (l.storageVideos, 'film', dirs['VIDEOS'] ?? '$home/Videos'),
      (l.storageTrash, 'trash', '${trashFolder(env)}/files'),
    ];
  }

  Future<void> _measure() async {
    final run = ServicesScope.of(context).host.run;
    for (final (_, _, path) in _folders(AppLocalizations.of(context))) {
      final size = await folderSize(run, path);
      if (!mounted) return;
      setState(() => _sizes[path] = size ?? 0);
    }
  }

  Future<void> _emptyTrash(String path) async {
    final l = AppLocalizations.of(context);
    final env = ServicesScope.of(context).env;
    final confirmed = await showConfirm(
      context,
      title: l.storageEmptyTrashTitle,
      message: l.storageEmptyTrashMessage,
      confirm: l.storageEmptyTrashButton,
      cancel: l.cancel,
    );
    if (!confirmed || !mounted) return;
    final ok = await emptyTrash(env);
    if (!mounted) return;
    setState(() {
      _trashError = ok ? null : l.storageEmptyTrashFailed;
      _sizes.remove(path);
    });
    final size = await folderSize(ServicesScope.of(context).host.run, path);
    if (mounted) setState(() => _sizes[path] = size ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    final folders = _folders(l);
    return PanePage(
      children: [
        const _DiskGroup(),
        SettingsGroup(
          children: [
            for (final (title, symbol, path) in folders)
              ValueRow(
                key: ValueKey('storage $symbol'),
                title: title,
                leading: IconTile(
                  symbol: symbol,
                  tint: const Color(0xFF9A9EA6),
                  size: 24,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_sizes.containsKey(path))
                      const AmalfiSpinner(size: AmalfiProgressSize.small)
                    else
                      Text(
                        formatBytes(_sizes[path] ?? 0),
                        style: settingsText(13, colors.secondary),
                      ),
                    if (symbol == 'trash') ...[
                      const SizedBox(width: 10),
                      AmalfiPushButton(
                        key: const ValueKey('empty trash'),
                        label: l.storageEmptyTrashButton,
                        size: AmalfiControlSize.small,
                        onPressed: (_sizes[path] ?? 0) > 0
                            ? () => _emptyTrash(path)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (_trashError case final error?) ErrorLine(error),
        const ApplicationsGroup(),
        const AppDataGroup(),
      ],
    );
  }
}

/// The data apps keep in `~/.var/app/<id>` (the sandbox's home of app bundles and Flatpak
/// apps): its size, and Delete for apps that are no longer installed.
class AppDataGroup extends StatefulWidget {
  const AppDataGroup({super.key});

  @override
  State<AppDataGroup> createState() => _AppDataGroupState();
}

class _AppDataGroupState extends State<AppDataGroup> {
  List<String>? _ids;
  Map<String, String> _names = const {};
  final Map<String, int> _sizes = {};
  String? _error;

  String get _root => '${ServicesScope.of(context).env['HOME'] ?? ''}/.var/app';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ids == null) unawaited(_load());
  }

  Future<void> _load() async {
    final root = Directory(_root);
    final ids = <String>[];
    try {
      for (final e in root.listSync()) {
        if (e is Directory) ids.add(e.path.split('/').last);
      }
    } on FileSystemException {
      // No app data yet.
    }
    ids.sort();
    final installed = await SilicaApps.list();
    if (!mounted) return;
    setState(() {
      _ids = ids;
      _names = {
        for (final a in installed ?? const <SilicaInstalledApp>[]) a.id: a.name,
      };
    });
    final run = ServicesScope.of(context).host.run;
    for (final id in ids) {
      final size = await folderSize(run, '$_root/$id');
      if (!mounted) return;
      setState(() => _sizes[id] = size ?? 0);
    }
  }

  Future<void> _delete(String id, String name) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showConfirm(
      context,
      title: l.storageDeleteDataTitle(name),
      message: l.storageDeleteDataMessage,
      confirm: l.storageDeleteData,
      cancel: l.cancel,
    );
    if (!confirmed || !mounted) return;
    try {
      Directory('$_root/$id').deleteSync(recursive: true);
      setState(() => _error = null);
    } on FileSystemException catch (e) {
      setState(() => _error = e.osError?.message ?? e.message);
    }
    _sizes.remove(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final ids = _ids ?? const [];
    if (ids.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SettingsGroup(
          heading: l.storageAppData,
          footer: l.storageAppDataHelp,
          children: [
            for (final id in ids)
              ValueRow(
                key: ValueKey('app data $id'),
                title: switch (_names[id]) {
                  final name? => name,
                  null => l.storageNotInstalled(id),
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_sizes.containsKey(id))
                      const AmalfiSpinner(size: AmalfiProgressSize.small)
                    else
                      Text(
                        formatBytes(_sizes[id] ?? 0),
                        style: settingsText(13, colors.secondary),
                      ),
                    // Only the data of apps that are gone: an installed app still uses its own.
                    if (!_names.containsKey(id)) ...[
                      const SizedBox(width: 10),
                      AmalfiPushButton(
                        key: ValueKey('delete data $id'),
                        label: l.storageDeleteData,
                        size: AmalfiControlSize.small,
                        onPressed: () => unawaited(_delete(id, id)),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
      ],
    );
  }
}

/// General › Sharing: the computer's name, editable; the sharing services wait for their
/// backends (#77).
class SharingPane extends StatefulWidget {
  const SharingPane({super.key});

  @override
  State<SharingPane> createState() => _SharingPaneState();
}

class _SharingPaneState extends State<SharingPane> {
  final TextEditingController _name = TextEditingController();
  String _saved = '';
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      ServicesScope.of(context).tools.computerName().then((name) {
        if (!mounted) return;
        setState(() {
          _saved = name;
          _name.text = name;
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name == _saved || _busy) return;
    setState(() => _busy = true);
    final error = await ServicesScope.of(context).tools.setComputerName(name);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _saved = name;
        _error = null;
      } else {
        _error = errorText(AppLocalizations.of(context), error);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AuthenticationBuilder(builder: _build);

  Widget _build(BuildContext context, bool? registered) {
    final l = AppLocalizations.of(context);
    final allowed = registered == true;
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.sharingServices,
          unavailable: true,
          issue: Issues.general,
          children: [
            for (final (title, symbol, tint) in [
              (l.sharingFiles, 'folder', const Color(0xFF00AFAA)),
              (l.sharingScreen, 'screen-share', const Color(0xFF8B5CF6)),
              (l.sharingRemoteLogin, 'terminal', const Color(0xFF5F636B)),
            ])
              ValueRow(
                title: title,
                height: 48,
                leading: IconTile(symbol: symbol, tint: tint, size: 24),
                trailing: const AmalfiSwitch(
                  value: false,
                  onChanged: null,
                  size: AmalfiControlSize.mini,
                ),
              ),
          ],
        ),
        SettingsGroup(
          footer: [
            l.sharingNameHelp(HostSystemTools.hostnameFor(_saved)),
            if (registered == false) l.errorAuthentication,
          ].join(' '),
          children: [
            ValueRow(
              title: l.sharingComputerName,
              trailing: SizedBox(
                width: 220,
                child: AmalfiTextField(
                  key: const ValueKey('computer name'),
                  controller: _name,
                  enabled: allowed,
                  semanticLabel: l.sharingComputerName,
                  onSubmitted: (_) => _save(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
        ButtonBar(
          leading: [
            if (_busy) const AmalfiSpinner(size: AmalfiProgressSize.small),
          ],
          buttons: [
            AmalfiPushButton(
              key: const ValueKey('rename computer'),
              label: l.sharingRename,
              size: AmalfiControlSize.small,
              onPressed:
                  !allowed ||
                      _busy ||
                      _name.text.trim().isEmpty ||
                      _name.text.trim() == _saved
                  ? null
                  : _save,
            ),
          ],
        ),
      ],
    );
  }
}

/// Picks one of many values (time zones, languages) with a search field.
Future<String?> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<String> values,
  required String current,
  String Function(String)? label,
}) => showAmalfiSheet<String>(
  context,
  semanticLabel: title,
  builder: (context, sheet) => _ChoiceSheet(
    title: title,
    values: values,
    current: current,
    label: label ?? (v) => v,
    close: sheet.close,
  ),
);

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.values,
    required this.current,
    required this.label,
    required this.close,
  });
  final String title;
  final List<String> values;
  final String current;
  final String Function(String) label;
  final void Function([String?]) close;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  final TextEditingController _query = TextEditingController();
  late String _chosen = widget.current;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final v in widget.values)
        if (q.isEmpty ||
            v.toLowerCase().contains(q) ||
            widget.label(v).toLowerCase().contains(q))
          v,
    ];
    return SizedBox(
      width: 460,
      height: 420,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: settingsText(13, colors.text, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            AmalfiSearchField(
              key: const ValueKey('choice search'),
              placeholder: l.searchPlaceholder,
              clearLabel: l.searchClear,
              controller: _query,
              autofocus: true,
              width: double.infinity,
              onChanged: (_) => setState(() {}),
              onCleared: () => setState(_query.clear),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GroupBox(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemExtent: 26,
                  itemBuilder: (context, i) {
                    final v = shown[i];
                    final chosen = v == _chosen;
                    return GestureDetector(
                      key: ValueKey('choice $v'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _chosen = v),
                      onDoubleTap: () => widget.close(v),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: chosen ? ControlAccent.of(context) : null,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.label(v),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: settingsText(
                            13,
                            chosen ? const Color(0xFFFFFFFF) : colors.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AmalfiPushButton(label: l.cancel, onPressed: widget.close),
                const SizedBox(width: 8),
                AmalfiPushButton(
                  key: const ValueKey('choice done'),
                  label: l.choose,
                  variant: AmalfiPushButtonVariant.primary,
                  onPressed: () => widget.close(_chosen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// General › Date & Time: automatic time, the date and time now, the time zone.
class DateTimePane extends StatefulWidget {
  const DateTimePane({super.key});

  @override
  State<DateTimePane> createState() => _DateTimePaneState();
}

class _DateTimePaneState extends State<DateTimePane> {
  ClockState? _clock;
  String? _error;
  Timer? _tick;
  DateTime _now = DateTime.now();

  SystemTools get _tools => ServicesScope.of(context).tools;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tick == null) {
      _load();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final clock = await _tools.clock();
    if (mounted) setState(() => _clock = clock);
  }

  Future<void> _run(Future<ToolError?> change) async {
    final error = await change;
    if (!mounted) return;
    setState(
      () => _error = error == null
          ? null
          : errorText(AppLocalizations.of(context), error),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AuthenticationBuilder(builder: _build);

  Widget _build(BuildContext context, bool? registered) {
    final l = AppLocalizations.of(context);
    final allowed = registered == true;
    final needsAgent = registered == false ? l.errorAuthentication : null;
    final clock = _clock ?? const ClockState();
    final settings = ServicesScope.of(context).settings;
    final style = ClockStyle.of(settings);
    void setClock(ClockStyle next) => setState(() => settings.writeClock(next));
    final zone = clock.timezone.isNotEmpty
        ? clock.timezone
        : HostInfoScope.of(context).timezone;
    String two(int n) => n.toString().padLeft(2, '0');
    final now =
        '${_now.year}-${two(_now.month)}-${two(_now.day)}, '
        '${two(_now.hour)}:${two(_now.minute)}:${two(_now.second)}';
    return PanePage(
      children: [
        SettingsGroup(
          footer: needsAgent,
          children: [
            SwitchRow(
              key: const ValueKey('automatic time'),
              title: l.dateTimeAutomatic,
              subtitle: clock.ntp && clock.synchronized
                  ? l.dateTimeSynchronized
                  : null,
              value: clock.ntp,
              onChanged: !allowed || _clock == null || !clock.canNtp
                  ? null
                  : (v) => _run(_tools.setNtp(v)),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            ValueRow(
              key: const ValueKey('date now'),
              title: l.dateTimeNow,
              trailing: RowValue(now),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.dateTimeMenuBarClock,
          footer: l.dateTimeClockHelp,
          children: [
            SwitchRow(
              key: const ValueKey('clock 24 hour'),
              title: l.dateTime24Hour,
              value: style.hour24,
              onChanged: (v) => setClock(style.copyWith(hour24: v)),
            ),
            SwitchRow(
              key: const ValueKey('clock seconds'),
              title: l.dateTimeSeconds,
              value: style.seconds,
              onChanged: (v) => setClock(style.copyWith(seconds: v)),
            ),
            SwitchRow(
              key: const ValueKey('clock weekday'),
              title: l.dateTimeWeekday,
              value: style.weekday,
              onChanged: (v) => setClock(style.copyWith(weekday: v)),
            ),
            PopUpRow<ClockDate>(
              key: const ValueKey('clock date'),
              title: l.dateTimeDate,
              items: [
                PopUpItem(ClockDate.auto, l.dateTimeDateAuto),
                PopUpItem(ClockDate.always, l.dateTimeDateAlways),
                PopUpItem(ClockDate.never, l.dateTimeDateNever),
              ],
              value: style.date,
              onChanged: (v) => setClock(style.copyWith(date: v)),
            ),
          ],
        ),
        SettingsGroup(
          footer: needsAgent,
          children: [
            ValueRow(
              key: const ValueKey('time zone'),
              title: l.dateTimeZone,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RowValue(zone.isEmpty ? l.aboutUnknown : zone),
                  const SizedBox(width: 10),
                  AmalfiPushButton(
                    key: const ValueKey('change time zone'),
                    label: l.changeButton,
                    size: AmalfiControlSize.small,
                    onPressed: !allowed
                        ? null
                        : () async {
                            final zones = await _tools.timezones();
                            if (!context.mounted || zones.isEmpty) return;
                            final chosen = await showChoiceSheet(
                              context,
                              title: l.dateTimeChooseZone,
                              values: zones,
                              current: zone,
                              label: (z) => z.replaceAll('_', ' '),
                            );
                            if (chosen != null && chosen != zone) {
                              await _run(_tools.setTimezone(chosen));
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
      ],
    );
  }
}

/// A locale's readable name: `it_IT.UTF-8` → `it_IT`.
String localeLabel(String locale) => locale.split('.').first;

/// General › Language & Region: the system language and the region's formats.
class LanguagePane extends StatefulWidget {
  const LanguagePane({super.key});

  @override
  State<LanguagePane> createState() => _LanguagePaneState();
}

class _LanguagePaneState extends State<LanguagePane> {
  LocaleState? _locale;
  String? _error;
  bool _loaded = false;

  SystemTools get _tools => ServicesScope.of(context).tools;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final locale = await _tools.locale();
    if (mounted) setState(() => _locale = locale);
  }

  Future<void> _choose({required bool formats}) async {
    final l = AppLocalizations.of(context);
    final locale = _locale ?? const LocaleState();
    final all = await _tools.locales();
    if (!mounted || all.isEmpty) return;
    final current = formats && locale.formats.isNotEmpty
        ? locale.formats
        : locale.language;
    final chosen = await showChoiceSheet(
      context,
      title: formats ? l.languageChooseRegion : l.languageChooseLanguage,
      values: all,
      current: current,
      label: localeLabel,
    );
    if (chosen == null || chosen == current) return;
    final error = await _tools.setLocale(
      language: formats ? locale.language : chosen,
      formats: formats ? chosen : locale.formats,
    );
    if (!mounted) return;
    setState(() => _error = error == null ? null : errorText(l, error));
    await _load();
  }

  @override
  Widget build(BuildContext context) => AuthenticationBuilder(builder: _build);

  Widget _build(BuildContext context, bool? registered) {
    final l = AppLocalizations.of(context);
    final allowed = registered == true;
    final info = HostInfoScope.of(context);
    final locale = _locale ?? const LocaleState();
    final language = locale.language.isNotEmpty
        ? locale.language
        : info.language;
    final formats = locale.formats.isNotEmpty ? locale.formats : language;
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.languagePreferred,
          footer: [
            l.languageNextLogin,
            if (registered == false) l.errorAuthentication,
          ].join(' '),
          children: [
            ValueRow(
              key: const ValueKey('system language'),
              title: l.languageSystem,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RowValue(
                    language.isEmpty ? l.aboutUnknown : localeLabel(language),
                  ),
                  const SizedBox(width: 10),
                  AmalfiPushButton(
                    key: const ValueKey('change language'),
                    label: l.changeButton,
                    size: AmalfiControlSize.small,
                    onPressed: allowed ? () => _choose(formats: false) : null,
                  ),
                ],
              ),
            ),
            ValueRow(
              key: const ValueKey('region formats'),
              title: l.languageRegion,
              subtitle: l.languageRegionHelp,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RowValue(
                    formats.isEmpty ? l.aboutUnknown : localeLabel(formats),
                  ),
                  const SizedBox(width: 10),
                  AmalfiPushButton(
                    key: const ValueKey('change region'),
                    label: l.changeButton,
                    size: AmalfiControlSize.small,
                    onPressed: allowed ? () => _choose(formats: true) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
      ],
    );
  }
}

class _SoftwareUpdatePane extends StatefulWidget {
  const _SoftwareUpdatePane();

  @override
  State<_SoftwareUpdatePane> createState() => _SoftwareUpdatePaneState();
}

/// General › Software Update (silica-desktop docs/spec/updates.md): the system, the app
/// bundles, AppImages and Flatpak apps together, from silica-daemon's Updates1. It checks when
/// opened and with Check Now; nothing installs without a click.
class _SoftwareUpdatePaneState extends State<_SoftwareUpdatePane> {
  List<SilicaUpdate>? _updates;
  bool _checking = false;
  bool _missing = false;
  final Map<String, String> _results = {};
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final updates = await SilicaUpdates.check();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _missing = updates == null;
      _updates = updates ?? const [];
    });
  }

  Future<void> _update(String id) async {
    setState(() => _busy.add(id));
    final result = await SilicaUpdates.update(id);
    if (!mounted) return;
    setState(() {
      _busy.remove(id);
      _results[id] = result;
    });
  }

  String _result(AppLocalizations l, String result) => switch (result) {
    'installed' => l.updateInstalledNow,
    'pending_restart' => l.updatePendingRestart,
    'staged' => l.updateStaged,
    final other => l.updateFailed(
      other.replaceFirst(RegExp(r'^failed:?\s*'), ''),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = HostInfoScope.of(context);
    final updates = _updates ?? const [];
    final pending = [
      for (final u in updates)
        if (!_results.containsKey(u.id)) u,
    ];
    final settings = ServicesScope.of(context).settings;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ValueRow(
              title: l.updateInstalled,
              trailing: RowValue(
                info.osPrettyName.isEmpty ? l.aboutUnknown : info.osPrettyName,
              ),
            ),
            ButtonRow(
              key: const ValueKey('update check'),
              title: _checking
                  ? l.updateChecking
                  : _missing
                  ? l.updateUnavailable
                  : updates.isEmpty
                  ? l.updateNone
                  : l.updateCheck,
              label: l.updateCheckButton,
              onPressed: _checking ? null : () => unawaited(_check()),
            ),
          ],
        ),
        // The daemon's daily check and the automatic install (Settings1, updates.md).
        ListenableBuilder(
          listenable: settings.watch(const [
            'updates.autoCheck',
            'updates.autoInstall',
          ]),
          builder: (context, _) {
            final check = settings.getBool('updates.autoCheck', fallback: true);
            final install = settings.getBool(
              'updates.autoInstall',
              fallback: false,
            );
            return SettingsGroup(
              children: [
                SwitchRow(
                  key: const ValueKey('update auto check'),
                  title: l.updateAutoCheck,
                  value: check,
                  onChanged: (on) =>
                      unawaited(settings.set('updates.autoCheck', on)),
                ),
                SwitchRow(
                  key: const ValueKey('update auto install'),
                  title: l.updateAutoInstall,
                  value: install,
                  onChanged: check
                      ? (on) =>
                            unawaited(settings.set('updates.autoInstall', on))
                      : null,
                ),
              ],
            );
          },
        ),
        if (updates.isNotEmpty)
          SettingsGroup(
            children: [
              for (final u in updates)
                ButtonRow(
                  key: ValueKey('update ${u.id}'),
                  title: u.kind == 'system' ? l.updateSystem : u.name,
                  subtitle: switch (_results[u.id]) {
                    final result? => _result(l, result),
                    null =>
                      u.current.isEmpty
                          ? l.updateTo(u.available)
                          : l.updateFrom(u.current, u.available),
                  },
                  label: l.updateButton,
                  onPressed: _results.containsKey(u.id) || _busy.contains(u.id)
                      ? null
                      : () => unawaited(_update(u.id)),
                ),
            ],
          ),
        if (pending.length > 1)
          ButtonBar(
            buttons: [
              AmalfiPushButton(
                key: const ValueKey('update all'),
                label: l.updateAll,
                onPressed: _busy.isNotEmpty
                    ? null
                    : () async {
                        for (final u in pending) {
                          await _update(u.id);
                        }
                      },
              ),
            ],
          ),
      ],
    );
  }
}

class _UnavailableSubPane extends StatelessWidget {
  const _UnavailableSubPane();

  @override
  Widget build(BuildContext context) => PanePage(
    children: [
      SettingsGroup(
        children: [
          EmptyState(
            AppLocalizations.of(context).notAvailableYet,
            key: const ValueKey('unavailable'),
          ),
        ],
      ),
    ],
  );
}
