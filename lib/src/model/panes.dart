// The panes of the sidebar, in the measured order (docs/spec/panes.md, ST-NAV-02). The grouping
// into blocks separated by ~13 pt is measured; which pane closes each block is not, and
// follows the order of topics (network, system, attention, security, accounts, input):
// provisional. The reference's panes for its own online services (assistant, game service,
// cloud account, payments) have no counterpart in Silica and are left out.

import 'dart:ui' show Color;

/// A pane of the sidebar.
enum PaneId {
  wifi('wifi', Color(0xFF0E77E6)),
  bluetooth('bluetooth', Color(0xFF0E77E6)),
  network('globe', Color(0xFF0E77E6)),
  vpn('network', Color(0xFF0E77E6)),
  energy('bolt-fill', Color(0xFF34A853)),
  battery('battery', Color(0xFF34A853)),
  general('gear', Color(0xFF9A9EA6)),
  accessibility('accessibility', Color(0xFF0E77E6)),
  appearance('appearance', Color(0xFF5F636B)),
  menuBar('menubar', Color(0xFF9A9EA6)),
  displays('display', Color(0xFF0E77E6)),
  desktopDock('dock', Color(0xFF5F636B)),
  wallpaper('photo', Color(0xFF00AFAA)),
  search('search', Color(0xFF9A9EA6)),
  notifications('bell-badge', Color(0xFFF0562E)),
  sound('volume', Color(0xFFF0562E)),
  focus('moon', Color(0xFF8B5CF6)),
  screenTime('hourglass', Color(0xFF8B5CF6)),
  lockScreen('lock', Color(0xFF5F636B)),
  privacy('shield', Color(0xFF0E77E6)),
  password('key', Color(0xFFF0562E)),
  users('person-2', Color(0xFF0E77E6)),
  internetAccounts('at', Color(0xFF0E77E6)),
  keyboard('keyboard', Color(0xFF9A9EA6)),
  mouse('mouse', Color(0xFF9A9EA6)),
  trackpad('pointer-fill', Color(0xFF9A9EA6)),
  printers('printer', Color(0xFF9A9EA6));

  const PaneId(this.symbol, this.tint);

  /// The silica-icons symbol (`symbols/regular/<symbol>.svg`), white on [tint].
  final String symbol;

  /// The fill of the rounded square behind the symbol (provisional colours: the reference's
  /// are coloured squares, not measured one by one).
  final Color tint;
}

/// The sidebar blocks, top to bottom. [hasBattery] swaps Energy for Battery, as on a
/// machine with a battery; [hasTrackpad] adds Trackpad after Mouse, as on a machine with a
/// touchpad (silica-daemon's `input.touchpad`).
List<List<PaneId>> paneGroups({
  required bool hasBattery,
  bool hasTrackpad = false,
}) => [
  [
    PaneId.wifi,
    PaneId.bluetooth,
    PaneId.network,
    PaneId.vpn,
    hasBattery ? PaneId.battery : PaneId.energy,
  ],
  [
    PaneId.general,
    PaneId.accessibility,
    PaneId.appearance,
    PaneId.menuBar,
    PaneId.displays,
    PaneId.desktopDock,
    PaneId.wallpaper,
    PaneId.search,
  ],
  [PaneId.notifications, PaneId.sound, PaneId.focus, PaneId.screenTime],
  [PaneId.lockScreen, PaneId.privacy, PaneId.password, PaneId.users],
  [PaneId.internetAccounts],
  [
    PaneId.keyboard,
    PaneId.mouse,
    if (hasTrackpad) PaneId.trackpad,
    PaneId.printers,
  ],
];

/// The sub-panes that have their own page (pushed inside a pane, with Back).
enum SubPaneId {
  about,
  softwareUpdate,
  storage,
  sharing,
  dateTime,
  startupDisk,
  loginItems,
  languageRegion,
  backups,
  transferReset,

  /// Accessibility › Display, › Motion and › Larger Text.
  accessibilityDisplay,
  accessibilityMotion,
  accessibilityLargerText,

  /// Notifications › one app ([Location.detail] is its key and name).
  notificationApp,
}

/// Where the window is: a pane, optionally one of its sub-panes.
class Location {
  const Location(this.pane, [this.sub, this.detail = '']);
  final PaneId pane;
  final SubPaneId? sub;

  /// What a sub-pane shows, when it shows one of many (an app's notifications).
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is Location &&
      other.pane == pane &&
      other.sub == sub &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(pane, sub, detail);

  @override
  String toString() => sub == null
      ? pane.name
      : '${pane.name}/${sub!.name}${detail.isEmpty ? '' : '/$detail'}';
}

/// The key and the name of a notifying app, kept together in [Location.detail].
(String key, String name) appDetail(String detail) {
  final at = detail.indexOf('\u001f');
  return at < 0
      ? (detail, detail)
      : (detail.substring(0, at), detail.substring(at + 1));
}

String encodeAppDetail(String key, String name) => '$key\u001f$name';

/// The places that open with a large centred header card (General): the toolbar leaves their
/// title out until the card scrolls away (ST-NAV-01; the smaller cards keep the title).
bool hasHeaderCard(Location at) => at.sub == null && at.pane == PaneId.general;
