// General › Storage › Applications (docs/design/amalfi/app-installation.md, section 5): one row
// per installed app, largest first, with Remove: a bundle or AppImage goes to the Trash, a
// Flatpak app is uninstalled, a running app is asked to quit first (`Quit and Move`).

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../system/app_install.dart';
import '../ui/app_install.dart';
import '../ui/grouped.dart';
import '../ui/popup.dart';
import 'general.dart' show formatBytes;

class ApplicationsGroup extends StatefulWidget {
  const ApplicationsGroup({super.key, this.procRoot = '/proc'});

  /// Where processes are looked up (tests).
  final String procRoot;

  @override
  State<ApplicationsGroup> createState() => _ApplicationsGroupState();
}

class _ApplicationsGroupState extends State<ApplicationsGroup> {
  List<StorageApp>? _apps;
  String? _error;
  StreamSubscription<SilicaAppsEvent>? _events;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    try {
      _events = SilicaApps.events().listen((event) {
        if (event.change != SilicaAppsChange.defaultChanged) {
          unawaited(_load());
        }
      }, onError: (Object _) {});
    } on Object {
      // No registry to watch.
    }
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final installed = await SilicaApps.list();
    if (!mounted || generation != _generation) return;
    if (installed == null) {
      setState(() => _apps = const []);
      return;
    }
    final services = ServicesScope.of(context);
    final old = {for (final a in _apps ?? const <StorageApp>[]) a.id: a};
    setState(
      () => _apps = [
        for (final a in storageApps(installed))
          a.copyWith(size: old[a.id]?.size, remote: old[a.id]?.remote),
      ],
    );
    for (final app in [..._apps!]) {
      final size = await measureApp(services.host.run, app, services.env);
      final remote = app.kind == StorageAppKind.flatpak
          ? await flatpakRemote(services.host.run, app.id)
          : null;
      if (!mounted || generation != _generation) return;
      setState(
        () => _apps = [
          for (final a in _apps!)
            a.id == app.id ? a.copyWith(size: size ?? 0, remote: remote) : a,
        ],
      );
    }
  }

  Future<void> _remove(StorageApp app) async {
    final l = AppLocalizations.of(context);
    final env = ServicesScope.of(context).env;
    final pid = runningPid(env, app.id, procRoot: widget.procRoot);
    if (pid != null) {
      final go = await showConfirm(
        context,
        title: l.storageQuitAndMoveTitle(app.name),
        message: '',
        confirm: l.storageQuitAndMove,
        cancel: l.cancel,
        cancelDefault: true,
      );
      if (!go || !mounted) return;
      final gone = await quitProcess(pid, procRoot: widget.procRoot);
      if (!mounted) return;
      if (!gone) {
        setState(() => _error = l.storageQuitFailed(app.name));
        return;
      }
    }
    String? error;
    if (app.kind == StorageAppKind.flatpak) {
      if (!await SilicaApps.uninstall(app.id)) {
        error = l.storageRemoveFailed(app.name);
      }
    } else {
      error = await moveToTrash(env, app.path);
      if (error != null) error = l.storageRemoveFailedReason(app.name, error);
    }
    if (!mounted) return;
    setState(() => _error = error);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final apps = sortedBySize(_apps ?? const []);
    if (apps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          heading: l.storageApplications,
          children: [
            for (final app in apps)
              StorageAppRow(
                key: ValueKey('storage app ${app.id}'),
                icon: app.icon,
                name: app.name,
                kind: storageKindLabel(
                  kind: app.kind,
                  remote: app.remote,
                  bundle: l.storageKindBundle,
                  flatpak: l.storageKindFlatpak,
                  appImage: l.storageKindAppImage,
                  system: l.storageKindSystem,
                ),
                size: app.size == null ? null : formatBytes(app.size!),
                removeLabel: l.storageRemoveApp(app.name),
                onRemove: app.removable ? () => unawaited(_remove(app)) : null,
              ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
      ],
    );
  }
}
