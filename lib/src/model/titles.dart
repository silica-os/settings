// Localized names of the panes and sub-panes, and the search index of the sidebar (ST-NAV-03):
// every setting reachable by name, with the path to it.

import '../../l10n/gen/app_localizations.dart';
import 'panes.dart';

String paneTitle(AppLocalizations l, PaneId pane) => switch (pane) {
  PaneId.wifi => l.paneWifi,
  PaneId.bluetooth => l.paneBluetooth,
  PaneId.network => l.paneNetwork,
  PaneId.vpn => l.paneVpn,
  PaneId.energy => l.paneEnergy,
  PaneId.battery => l.paneBattery,
  PaneId.general => l.paneGeneral,
  PaneId.accessibility => l.paneAccessibility,
  PaneId.appearance => l.paneAppearance,
  PaneId.menuBar => l.paneMenuBar,
  PaneId.displays => l.paneDisplays,
  PaneId.desktopDock => l.paneDesktopDock,
  PaneId.wallpaper => l.paneWallpaper,
  PaneId.search => l.paneSearch,
  PaneId.notifications => l.paneNotifications,
  PaneId.sound => l.paneSound,
  PaneId.focus => l.paneFocus,
  PaneId.screenTime => l.paneScreenTime,
  PaneId.lockScreen => l.paneLockScreen,
  PaneId.privacy => l.panePrivacy,
  PaneId.password => l.panePassword,
  PaneId.users => l.paneUsers,
  PaneId.internetAccounts => l.paneInternetAccounts,
  PaneId.keyboard => l.paneKeyboard,
  PaneId.mouse => l.paneMouse,
  PaneId.trackpad => l.paneTrackpad,
  PaneId.printers => l.panePrinters,
};

String subTitle(AppLocalizations l, SubPaneId sub) => switch (sub) {
  SubPaneId.about => l.subAbout,
  SubPaneId.softwareUpdate => l.subSoftwareUpdate,
  SubPaneId.storage => l.subStorage,
  SubPaneId.sharing => l.subSharing,
  SubPaneId.dateTime => l.subDateTime,
  SubPaneId.startupDisk => l.subStartupDisk,
  SubPaneId.loginItems => l.subLoginItems,
  SubPaneId.languageRegion => l.subLanguageRegion,
  SubPaneId.backups => l.subBackups,
  SubPaneId.transferReset => l.subTransferReset,
  SubPaneId.accessibilityDisplay => l.accessibilityDisplay,
  SubPaneId.accessibilityMotion => l.accessibilityMotion,
  SubPaneId.accessibilityLargerText => l.accessibilityLargerText,
  SubPaneId.notificationApp => l.paneNotifications,
};

/// The title the toolbar shows for a place.
String locationTitle(AppLocalizations l, Location at) {
  final sub = at.sub;
  if (sub == SubPaneId.notificationApp) return appDetail(at.detail).$2;
  return sub == null ? paneTitle(l, at.pane) : subTitle(l, sub);
}

/// A search result: a setting's name and where it lives.
class SearchEntry {
  const SearchEntry(this.title, this.location);
  final String title;
  final Location location;

  /// "Pane → Sub-pane", in secondary gray under the title.
  String path(AppLocalizations l) {
    final sub = location.sub;
    final pane = paneTitle(l, location.pane);
    return sub == null ? pane : '$pane → ${subTitle(l, sub)}';
  }
}

/// Every searchable setting of the panes shown in the sidebar.
List<SearchEntry> searchIndex(AppLocalizations l, Iterable<PaneId> panes) {
  final shown = panes.toSet();
  SearchEntry at(String title, PaneId pane, [SubPaneId? sub]) =>
      SearchEntry(title, Location(pane, sub));
  final all = [
    for (final pane in shown) at(paneTitle(l, pane), pane),
    for (final sub in SubPaneId.values)
      if (sub != SubPaneId.notificationApp &&
          sub != SubPaneId.accessibilityDisplay &&
          sub != SubPaneId.accessibilityMotion &&
          sub != SubPaneId.accessibilityLargerText)
        at(subTitle(l, sub), PaneId.general, sub),
    at(
      l.accessibilityDisplay,
      PaneId.accessibility,
      SubPaneId.accessibilityDisplay,
    ),
    at(
      l.accessibilityMotion,
      PaneId.accessibility,
      SubPaneId.accessibilityMotion,
    ),
    at(
      l.accessibilityLargerText,
      PaneId.accessibility,
      SubPaneId.accessibilityLargerText,
    ),
    at(
      l.accessibilityPointerSize,
      PaneId.accessibility,
      SubPaneId.accessibilityDisplay,
    ),
    at(
      l.accessibilityIncreaseContrast,
      PaneId.accessibility,
      SubPaneId.accessibilityDisplay,
    ),
    at(
      l.accessibilityReduceTransparency,
      PaneId.accessibility,
      SubPaneId.accessibilityDisplay,
    ),
    at(
      l.accessibilityReduceMotion,
      PaneId.accessibility,
      SubPaneId.accessibilityMotion,
    ),
    at(l.wifiKnownNetworks, PaneId.wifi),
    at(l.wifiOtherNetworks, PaneId.wifi),
    at(l.bluetoothMyDevices, PaneId.bluetooth),
    at(l.appearanceAccent, PaneId.appearance),
    at(l.appearanceMode, PaneId.appearance),
    at(l.appearanceSidebarIconSize, PaneId.appearance),
    at(l.appearanceScrollBars, PaneId.appearance),
    at(l.dockMagnification, PaneId.desktopDock),
    at(l.dockRecents, PaneId.desktopDock),
    at(l.dockSize, PaneId.desktopDock),
    at(l.dockHotCorners, PaneId.desktopDock),
    at(l.displaysResolution, PaneId.displays),
    at(l.displaysNightLight, PaneId.displays),
    at(l.soundOutputVolume, PaneId.sound),
    at(l.soundOutputDevice, PaneId.sound),
    at(l.soundAlertVolume, PaneId.sound),
    at(l.focusDoNotDisturb, PaneId.focus),
    at(l.keyboardRepeatRate, PaneId.keyboard),
    at(l.keyboardRepeatDelay, PaneId.keyboard),
    at(l.keyboardShortcuts, PaneId.keyboard),
    at(l.lockDisplayOff, PaneId.lockScreen),
    at(l.lockPasswordDelay, PaneId.lockScreen),
    at(l.aboutProcessor, PaneId.general, SubPaneId.about),
    at(l.aboutMemory, PaneId.general, SubPaneId.about),
    at(l.mousePointerSpeed, PaneId.mouse),
    at(l.mouseNaturalScrolling, PaneId.mouse),
    at(l.mouseScrollSpeed, PaneId.mouse),
    at(l.trackpadTrackingSpeed, PaneId.trackpad),
    at(l.trackpadTapToClick, PaneId.trackpad),
    at(l.mouseNaturalScrolling, PaneId.trackpad),
    at(l.energyPreventSleep, PaneId.energy),
    at(l.soundInputVolume, PaneId.sound),
    at(l.notificationsApps, PaneId.notifications),
    at(l.dockAutoHide, PaneId.desktopDock),
    at(l.dockPosition, PaneId.desktopDock),
    at(l.dockMinimizeEffect, PaneId.desktopDock),
    at(l.desktopDefaultBrowser, PaneId.desktopDock),
    at(l.dateTimeZone, PaneId.general, SubPaneId.dateTime),
    at(l.sharingComputerName, PaneId.general, SubPaneId.sharing),
    at(l.languageRegion, PaneId.general, SubPaneId.languageRegion),
    at(l.batteryLowPowerMode, PaneId.battery),
    at(l.batteryLowPowerMode, PaneId.energy),
    at(l.menuBarControls, PaneId.menuBar),
  ];
  return [
    for (final entry in all)
      if (shown.contains(entry.location.pane)) entry,
  ];
}

/// The entries whose title contains [query] (case-insensitive), panes first.
List<SearchEntry> searchMatches(List<SearchEntry> index, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final matches = [
    for (final entry in index)
      if (entry.title.toLowerCase().contains(q)) entry,
  ];
  matches.sort((a, b) {
    final aStarts = a.title.toLowerCase().startsWith(q) ? 0 : 1;
    final bStarts = b.title.toLowerCase().startsWith(q) ? 0 : 1;
    return aStarts.compareTo(bStarts);
  });
  // One row per distinct title and place.
  final seen = <String>{};
  return [
    for (final m in matches)
      if (seen.add('${m.title}|${m.location}')) m,
  ];
}
