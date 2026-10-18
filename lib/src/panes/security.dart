// Lock Screen (ST-LCK-01), Privacy and Security (ST-PRV-01), Login Password (ST-USR-01), Users
// and Groups (ST-USR-01), Internet Accounts (ST-ACN-01), Accessibility (ST-ACC-01/02) and
// Search (ST-SPT-01). Real: the user accounts (passwd and group, administrators from wheel).
// The lock screen is the shell's (#50): the password delay and the user's name are
// lockscreen.json; the display-off time is power.json's, which Ossido reads (#68). The
// accounts, privacy and search settings wait for their backends: each group names its issue.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../model/issues.dart';
import '../system/shell_config.dart';
import '../system/tools.dart';
import '../ui/grouped.dart';
import 'power.dart' show idleRow;

class LockScreenPane extends StatefulWidget {
  const LockScreenPane({super.key});

  @override
  State<LockScreenPane> createState() => _LockScreenPaneState();
}

class _LockScreenPaneState extends State<LockScreenPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The display turns off by power.json (Ossido, #68); the lock screen is the shell's.
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.lockPasswordDelayHelp,
          children: [
            idleRow(
              context,
              key: const ValueKey('lock display off'),
              title: l.lockDisplayOff,
              configKey: 'displayOffMinutes',
              changed: () => setState(() {}),
            ),
            passwordDelayRow(context, () => setState(() {})),
          ],
        ),
        SettingsGroup(
          children: [
            SwitchRow(
              key: const ValueKey('lock show user'),
              title: l.lockShowUser,
              value: ServicesScope.of(
                context,
              ).config.flag('lockscreen', 'showUser', fallback: true),
              onChanged: (on) => setState(
                () => ServicesScope.of(
                  context,
                ).config.write('lockscreen', 'showUser', on),
              ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.lockScreen,
          children: [
            SwitchRow(title: l.lockShowHints, value: false),
            SwitchRow(title: l.lockShowMessage, value: false),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.lockScreen,
          children: [
            ValueRow(
              title: l.lockLoginWindowShows,
              alignTop: true,
              trailing: SettingsRadioGroup<String>(
                options: [
                  RadioOption('list', l.lockListOfUsers),
                  RadioOption('fields', l.lockNameAndPassword),
                ],
                value: 'list',
                onChanged: (_) {},
              ),
            ),
            SwitchRow(title: l.lockShowPowerButtons, value: true),
          ],
        ),
      ],
    );
  }
}

/// The pop-up for the password delay: from the screen saver or the display turning off.
Widget passwordDelayRow(BuildContext context, VoidCallback changed) {
  final l = AppLocalizations.of(context);
  final config = ServicesScope.of(context).config;
  String label(int? seconds) => switch (seconds) {
    null => l.lockNever,
    0 => l.lockImmediately,
    < 60 => l.lockSeconds(seconds),
    final s when s % 3600 == 0 => l.lockHours(s ~/ 3600),
    final s => l.lockMinutes(s ~/ 60),
  };
  final saved = config.passwordDelay();
  // -1 stands for "never" (a pop-up value cannot be null).
  final choices = {...passwordDelayChoices, saved}.toList()
    ..sort((a, b) => (a ?? 1 << 40).compareTo(b ?? 1 << 40));
  return PopUpRow<int>(
    key: const ValueKey('lock password delay'),
    title: l.lockPasswordDelay,
    items: [for (final c in choices) PopUpItem(c ?? -1, label(c))],
    value: saved ?? -1,
    onChanged: (v) {
      config.writePasswordDelay(v < 0 ? null : v);
      changed();
    },
  );
}

class PrivacyPane extends StatelessWidget {
  const PrivacyPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.privacy.symbol,
          tint: PaneId.privacy.tint,
          title: l.panePrivacy,
          description: l.privacyDescription,
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.privacy,
          children: [
            for (final (title, symbol) in [
              (l.privacyLocation, 'location'),
              (l.privacyCamera, 'camera'),
              (l.privacyMicrophone, 'mic'),
              (l.privacyScreenRecording, 'record-circle'),
              (l.privacyFiles, 'folder'),
            ])
              NavRow(
                title: title,
                symbol: symbol,
                tint: PaneId.privacy.tint,
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

class PasswordPane extends StatelessWidget {
  const PasswordPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          issue: Issues.users,
          children: [
            ButtonRow(
              title: l.passwordLogin,
              subtitle: l.passwordSet,
              label: l.passwordChange,
              onPressed: () {},
            ),
            SwitchRow(title: l.passwordFingerprint, value: false),
          ],
        ),
      ],
    );
  }
}

class UsersPane extends StatefulWidget {
  const UsersPane({super.key});

  @override
  State<UsersPane> createState() => _UsersPaneState();
}

class _UsersPaneState extends State<UsersPane> {
  List<UserAccount>? _users;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_users == null) {
      ServicesScope.of(context).tools.users().then((u) {
        if (mounted) setState(() => _users = u);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = HostInfoScope.of(context);
    final colors = SettingsColors.of(context);
    final users = [...?_users];
    // Without passwd entries (a container), the session's user still shows.
    if (users.isEmpty && info.userLogin.isNotEmpty) {
      users.add(
        UserAccount(
          login: info.userLogin,
          name: info.userName,
          uid: 0,
          admin: true,
        ),
      );
    }
    users.sort((a, b) {
      if (a.login == info.userLogin) return -1;
      if (b.login == info.userLogin) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    Widget avatar(UserAccount u) => Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA5A5AA), Color(0xFF85858B)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        (u.name.isEmpty ? u.login : u.name).characters.first.toUpperCase(),
        style: settingsText(
          14,
          const Color(0xFFFFFFFF),
          weight: FontWeight.w600,
        ),
      ),
    );
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            for (final u in users)
              ValueRow(
                key: ValueKey(
                  u.login == info.userLogin
                      ? 'current user'
                      : 'user ${u.login}',
                ),
                height: 52,
                title: u.name,
                subtitle: [
                  u.login,
                  u.admin ? l.usersAdmin : l.usersStandard,
                ].join(' · '),
                leading: avatar(u),
                trailing: u.login == info.userLogin
                    ? Text(
                        l.usersYou,
                        style: settingsText(11, colors.secondary),
                      )
                    : null,
              ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.users,
          children: [
            SwitchRow(title: l.usersGuest, value: false),
            PopUpRow<int>(
              title: l.usersAutomaticLogin,
              items: [PopUpItem(0, l.lockNever)],
              value: 0,
              onChanged: (_) {},
            ),
            ButtonRow(
              title: l.usersAddUser,
              label: l.addButton,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class InternetAccountsPane extends StatelessWidget {
  const InternetAccountsPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          issue: Issues.internetAccounts,
          children: [
            EmptyState(l.accountsNone),
            ButtonRow(
              title: l.accountsAdd,
              label: l.addButton,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class AccessibilityPane extends StatelessWidget {
  const AccessibilityPane({super.key, required this.open});

  /// Opens a sub-pane (Display, Motion).
  final void Function(SubPaneId sub, [String detail]) open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const blue = Color(0xFF0E77E6);
    Widget group(String heading, List<(String, String)> rows) => SettingsGroup(
      heading: heading,
      unavailable: true,
      issue: Issues.accessibility,
      children: [
        for (final (title, symbol) in rows)
          NavRow(title: title, symbol: symbol, tint: blue, onTap: () {}),
      ],
    );
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.accessibility.symbol,
          tint: PaneId.accessibility.tint,
          title: l.paneAccessibility,
          description: l.accessibilityDescription,
        ),
        SettingsGroup(
          heading: l.accessibilityVision,
          children: [
            NavRow(
              key: const ValueKey('accessibility display'),
              title: l.accessibilityDisplay,
              symbol: 'display',
              tint: blue,
              onTap: () => open(SubPaneId.accessibilityDisplay),
            ),
            NavRow(
              key: const ValueKey('accessibility motion'),
              title: l.accessibilityMotion,
              symbol: 'circle-dot',
              tint: blue,
              onTap: () => open(SubPaneId.accessibilityMotion),
            ),
            NavRow(
              key: const ValueKey('accessibility larger text'),
              title: l.accessibilityLargerText,
              symbol: 'text-size',
              tint: blue,
              onTap: () => open(SubPaneId.accessibilityLargerText),
            ),
          ],
        ),
        group(l.accessibilityMoreVision, [
          (l.accessibilityScreenReader, 'speaker'),
          (l.accessibilityZoom, 'search'),
          (l.accessibilitySpokenContent, 'speaker'),
        ]),
        group(l.accessibilityPhysical, [
          (l.accessibilityVoiceControl, 'mic'),
          (l.paneKeyboard, 'keyboard'),
          (l.accessibilityPointer, 'mouse'),
        ]),
        group(l.accessibilityHearing, [
          (l.accessibilityAudio, 'speaker'),
          (l.accessibilityCaptions, 'captions'),
        ]),
      ],
    );
  }
}

/// Accessibility › Display: Reduce Transparency draws the glass opaque (Ossido and silica_ui);
/// Increase Contrast switches every app to the high-contrast palette (silica_ui).
class AccessibilityDisplayPane extends StatefulWidget {
  const AccessibilityDisplayPane({super.key});

  @override
  State<AccessibilityDisplayPane> createState() =>
      _AccessibilityDisplayPaneState();
}

class _AccessibilityDisplayPaneState extends State<AccessibilityDisplayPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.accessibilityReduceTransparencyHelp,
          children: [
            SwitchRow(
              key: const ValueKey('reduce transparency'),
              title: l.accessibilityReduceTransparency,
              value: services.reduceTransparency.value,
              onChanged: (on) =>
                  setState(() => services.setReduceTransparency(on)),
            ),
          ],
        ),
        SettingsGroup(
          footer: l.accessibilityPointerSizeHelp,
          children: [
            SliderRow(
              key: const ValueKey('pointer size'),
              title: l.accessibilityPointerSize,
              value: services.cursorSize.value.toDouble(),
              min: cursorSizeMin.toDouble(),
              max: cursorSizeMax.toDouble(),
              labels: [
                l.accessibilityPointerNormal,
                l.accessibilityPointerLarge,
              ],
              onChanged: (v) =>
                  setState(() => services.setCursorSize(v.round())),
            ),
          ],
        ),
        SettingsGroup(
          footer: l.accessibilityIncreaseContrastHelp,
          children: [
            SwitchRow(
              key: const ValueKey('increase contrast'),
              title: l.accessibilityIncreaseContrast,
              value: services.increaseContrast.value,
              onChanged: (on) =>
                  setState(() => services.setIncreaseContrast(on)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Accessibility › Larger Text: the apps' text grows by a factor (silica_ui, every app but the
/// shell).
class AccessibilityLargerTextPane extends StatefulWidget {
  const AccessibilityLargerTextPane({super.key});

  @override
  State<AccessibilityLargerTextPane> createState() =>
      _AccessibilityLargerTextPaneState();
}

class _AccessibilityLargerTextPaneState
    extends State<AccessibilityLargerTextPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.accessibilityLargerTextHelp,
          children: [
            SliderRow(
              key: const ValueKey('text size'),
              title: l.accessibilityTextSize,
              value: services.textScale.value,
              min: 1,
              max: 1.5,
              divisions: 5,
              labels: [l.accessibilityTextDefault, l.accessibilityTextLarger],
              onChanged: (v) => setState(() => services.setTextScale(v)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Accessibility › Motion: Reduce Motion skips Ossido's own animations and tells the apps
/// (`MediaQuery.disableAnimations`).
class AccessibilityMotionPane extends StatefulWidget {
  const AccessibilityMotionPane({super.key});

  @override
  State<AccessibilityMotionPane> createState() =>
      _AccessibilityMotionPaneState();
}

class _AccessibilityMotionPaneState extends State<AccessibilityMotionPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.accessibilityReduceMotionHelp,
          children: [
            SwitchRow(
              key: const ValueKey('reduce motion'),
              title: l.accessibilityReduceMotion,
              value: services.reduceMotion.value,
              onChanged: (on) => setState(() => services.setReduceMotion(on)),
            ),
          ],
        ),
      ],
    );
  }
}

class SearchPane extends StatelessWidget {
  const SearchPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.search.symbol,
          tint: PaneId.search.tint,
          title: l.paneSearch,
          description: l.searchDescription,
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.search,
          children: [
            SwitchRow(title: l.searchHelpImprove, value: false),
            SwitchRow(title: l.searchShowRelated, value: true),
          ],
        ),
        SettingsGroup(
          heading: l.searchResultsFromApps,
          unavailable: true,
          issue: Issues.search,
          children: [
            SwitchRow(title: l.searchApplications, value: true),
            SwitchRow(title: l.searchFolders, value: true),
            SwitchRow(title: l.searchCalculator, value: true),
          ],
        ),
      ],
    );
  }
}
