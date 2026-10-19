// The apps Settings lists and removes (Storage › Applications) and the pop-up widths of the
// Amalfi masters of app installation (docs/design/amalfi/app-installation.md, section 5).

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'host.dart';

/// An app in an [AppPopUp]: its id, name and icon (a silica-icons id).
@immutable
class AppChoice {
  const AppChoice({required this.id, required this.name, this.icon = ''});

  final String id;
  final String name;
  final String icon;
}

/// What an installed app is, for the Storage › Applications card.
enum StorageAppKind { bundle, appImage, flatpak, system }

/// One row of Storage › Applications.
@immutable
class StorageApp {
  const StorageApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.path,
    this.size,
    this.remote,
  });

  final String id;
  final String name;

  /// The silica-icons id (or icon folder) of the app.
  final String icon;
  final StorageAppKind kind;

  /// The bundle, the AppImage file or the system bundle; empty for Flatpak apps.
  final String path;

  /// Bytes, null while it is being measured.
  final int? size;

  /// The Flatpak remote ("flathub"), when known.
  final String? remote;

  /// System apps cannot be removed here.
  bool get removable => kind != StorageAppKind.system;

  StorageApp copyWith({int? size, String? remote}) => StorageApp(
    id: id,
    name: name,
    icon: icon,
    kind: kind,
    path: path,
    size: size ?? this.size,
    remote: remote ?? this.remote,
  );
}

/// The installed apps the Storage card lists: bundles, AppImages and Flatpak apps, and system
/// bundles. Apps without a Dock/Launcher presence (`no_display`) and the plain desktop entries
/// that are not bundles are skipped.
List<StorageApp> storageApps(Iterable<SilicaInstalledApp> installed) {
  final out = <StorageApp>[];
  for (final app in installed) {
    if (app.noDisplay) continue;
    final StorageAppKind kind;
    switch (app.kind) {
      case SilicaInstalledAppKind.bundle:
        kind = StorageAppKind.bundle;
      case SilicaInstalledAppKind.appimage:
        kind = StorageAppKind.appImage;
      case SilicaInstalledAppKind.flatpak:
        kind = StorageAppKind.flatpak;
      case SilicaInstalledAppKind.system:
        // A system bundle is a `.app` folder; any other system app is a desktop entry.
        if (!app.path.endsWith('.app')) continue;
        kind = StorageAppKind.system;
    }
    out.add(
      StorageApp(
        id: app.id,
        name: app.name,
        icon: app.silicaIcon.isNotEmpty ? app.silicaIcon : app.id,
        kind: kind,
        path: kind == StorageAppKind.flatpak ? '' : app.path,
      ),
    );
  }
  return out;
}

/// Largest first; apps whose size is not known yet go last. Equal sizes by name.
List<StorageApp> sortedBySize(Iterable<StorageApp> apps) {
  final list = [...apps];
  list.sort((a, b) {
    final x = a.size;
    final y = b.size;
    if (x != null && y != null && x != y) return y.compareTo(x);
    if ((x == null) != (y == null)) return x == null ? 1 : -1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}

/// The kinds' captions: "App bundle", "Flatpak · flathub", "AppImage", "System app".
String storageKindLabel({
  required StorageAppKind kind,
  String? remote,
  required String bundle,
  required String flatpak,
  required String appImage,
  required String system,
}) => switch (kind) {
  StorageAppKind.bundle => bundle,
  StorageAppKind.appImage => appImage,
  StorageAppKind.system => system,
  StorageAppKind.flatpak =>
    remote == null || remote.isEmpty ? flatpak : '$flatpak · $remote',
};

/// The folders a Flatpak app's files live in: system, then user installation.
List<String> flatpakFolders(String id, Map<String, String> env) {
  final home = env['HOME'] ?? '';
  final data = env['XDG_DATA_HOME'];
  final user = data != null && data.isNotEmpty ? data : '$home/.local/share';
  return [
    '/var/lib/flatpak/app/$id/current/active',
    '$user/flatpak/app/$id/current/active',
  ];
}

/// The bytes an app takes: the folder of a bundle or Flatpak app (`du`), the file of an
/// AppImage. Null when it cannot be measured. Runs off the UI thread (a child process).
Future<int?> measureApp(
  CommandRunner run,
  StorageApp app,
  Map<String, String> env,
) async {
  switch (app.kind) {
    case StorageAppKind.appImage:
      try {
        return await File(app.path).length();
      } on FileSystemException {
        return null;
      }
    case StorageAppKind.bundle || StorageAppKind.system:
      return folderSize(run, app.path);
    case StorageAppKind.flatpak:
      int? total;
      for (final folder in flatpakFolders(app.id, env)) {
        if (!Directory(folder).existsSync()) continue;
        final size = await folderSize(run, folder);
        if (size != null) total = (total ?? 0) + size;
      }
      return total;
  }
}

/// The remote a Flatpak app came from (`flatpak info --show-origin`), null when unknown.
Future<String?> flatpakRemote(CommandRunner run, String id) async {
  final out = await run('flatpak', ['info', '--show-origin', id]);
  final remote = out?.trim() ?? '';
  return remote.isEmpty || remote.contains('\n') ? null : remote;
}

/// The pid of a running instance of app [id]: a live `<id>.<pid>.sock` in
/// `$XDG_RUNTIME_DIR/silica-apps`. [procRoot] is `/proc`.
int? runningPid(
  Map<String, String> env,
  String id, {
  String procRoot = '/proc',
}) {
  final runtime = env['XDG_RUNTIME_DIR'];
  if (runtime == null || runtime.isEmpty) return null;
  try {
    final prefix = '$id.';
    for (final entry in Directory('$runtime/silica-apps').listSync()) {
      final name = entry.path.split('/').last;
      if (!name.startsWith(prefix) || !name.endsWith('.sock')) continue;
      final pid = int.tryParse(
        name.substring(prefix.length, name.length - '.sock'.length),
      );
      if (pid != null && pid > 0 && Directory('$procRoot/$pid').existsSync()) {
        return pid;
      }
    }
  } on FileSystemException {
    // No runtime folder: nothing runs.
  }
  return null;
}

/// Asks [pid] to quit (SIGTERM) and waits up to [timeout] for it to go. True once it is gone.
Future<bool> quitProcess(
  int pid, {
  String procRoot = '/proc',
  Duration timeout = const Duration(seconds: 5),
  Duration poll = const Duration(milliseconds: 100),
  bool Function(int pid)? signal,
}) async {
  (signal ?? (p) => Process.killPid(p, ProcessSignal.sigterm))(pid);
  final deadline = DateTime.now().add(timeout);
  while (Directory('$procRoot/$pid').existsSync()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(poll);
  }
  return true;
}

/// Moves [path] to the user's trash (freedesktop trash specification: `files` and a
/// `.trashinfo` record). Null on success, else the reason.
Future<String?> moveToTrash(
  Map<String, String> env,
  String path, {
  CommandRunner run = runCommand,
  DateTime? now,
}) async {
  final trash = trashFolder(env);
  try {
    Directory('$trash/files').createSync(recursive: true);
    Directory('$trash/info').createSync(recursive: true);
    final base = path.split('/').where((s) => s.isNotEmpty).last;
    var name = base;
    for (
      var n = 2;
      _exists('$trash/files/$name') || _exists('$trash/info/$name.trashinfo');
      n++
    ) {
      name = '$base $n';
    }
    final date = (now ?? DateTime.now()).toIso8601String().split('.').first;
    final encoded = path.split('/').map(Uri.encodeComponent).join('/');
    final info = File('$trash/info/$name.trashinfo')
      ..writeAsStringSync('[Trash Info]\nPath=$encoded\nDeletionDate=$date\n');
    final target = '$trash/files/$name';
    try {
      if (FileSystemEntity.isDirectorySync(path)) {
        Directory(path).renameSync(target);
      } else {
        File(path).renameSync(target);
      }
    } on FileSystemException {
      // Another file system: let mv copy it across.
      final moved = await run('mv', ['-T', '--', path, target]);
      if (moved == null) {
        info.deleteSync();
        return 'Could not move $path to the Trash';
      }
    }
    return null;
  } on FileSystemException catch (e) {
    return e.osError?.message ?? e.message;
  }
}

bool _exists(String path) =>
    FileSystemEntity.typeSync(path, followLinks: false) !=
    FileSystemEntityType.notFound;

/// The values of "Allow applications from": `flathub` and `trusted`, and `anywhere` only while
/// it is the current one (it is set from the command line).
List<String> appSourceValues(String current) => [
  'flathub',
  'trusted',
  if (current == 'anywhere') 'anywhere',
];

/// A pop-up button of the Regular size hugs its value: [text] + [extra], rounded up to 4.
double hugWidth(double text, double extra) => ((text + extra) / 4).ceil() * 4;

/// The width of the Regular pop-up (kit `Buttons/Pop-up/Regular`) for [label]: text + 40.
double regularPopUpWidth(String label) => hugWidth(_textWidth(label), 40);

/// The width of the App pop-up (kit `Buttons/Pop-up/App/Regular`) for [label]: text + 64.
double appPopUpWidth(String label) => hugWidth(_textWidth(label), 64);

double _textWidth(String label) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: AmalfiPopUpButtonMetrics.labelStyle(
        AmalfiControlSize.regular,
        const Color(0xFF000000),
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The apps of a Default apps pop-up: [ids] as choices, sorted by name.
List<AppChoice> defaultAppChoices(
  Iterable<String> ids,
  Map<String, SilicaInstalledApp> installed,
) {
  final out = [
    for (final id in ids)
      AppChoice(
        id: id,
        name: installed[id]?.name ?? id,
        icon: switch (installed[id]) {
          final app? when app.silicaIcon.isNotEmpty => app.silicaIcon,
          _ => id,
        },
      ),
  ];
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

/// The media types the Image viewer row sets together.
const List<String> imageTypes = [
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'image/tiff',
  'image/bmp',
  'image/svg+xml',
];
