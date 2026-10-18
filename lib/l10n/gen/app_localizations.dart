import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appTitle;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet in Silica.'**
  String get notAvailableYet;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit…'**
  String get edit;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchPlaceholder;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @accountLocal.
  ///
  /// In en, this message translates to:
  /// **'Local account'**
  String get accountLocal;

  /// No description provided for @accountLocalUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get accountLocalUser;

  /// No description provided for @paneWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get paneWifi;

  /// No description provided for @paneBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get paneBluetooth;

  /// No description provided for @paneNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get paneNetwork;

  /// No description provided for @paneVpn.
  ///
  /// In en, this message translates to:
  /// **'VPN'**
  String get paneVpn;

  /// No description provided for @paneEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get paneEnergy;

  /// No description provided for @paneBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get paneBattery;

  /// No description provided for @paneGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get paneGeneral;

  /// No description provided for @paneAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get paneAccessibility;

  /// No description provided for @paneAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get paneAppearance;

  /// No description provided for @paneMenuBar.
  ///
  /// In en, this message translates to:
  /// **'Menu Bar'**
  String get paneMenuBar;

  /// No description provided for @paneDisplays.
  ///
  /// In en, this message translates to:
  /// **'Displays'**
  String get paneDisplays;

  /// No description provided for @paneDesktopDock.
  ///
  /// In en, this message translates to:
  /// **'Desktop & Dock'**
  String get paneDesktopDock;

  /// No description provided for @paneWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get paneWallpaper;

  /// No description provided for @paneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get paneSearch;

  /// No description provided for @paneNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get paneNotifications;

  /// No description provided for @paneSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get paneSound;

  /// No description provided for @paneFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get paneFocus;

  /// No description provided for @paneScreenTime.
  ///
  /// In en, this message translates to:
  /// **'Screen Time'**
  String get paneScreenTime;

  /// No description provided for @paneLockScreen.
  ///
  /// In en, this message translates to:
  /// **'Lock Screen'**
  String get paneLockScreen;

  /// No description provided for @panePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get panePrivacy;

  /// No description provided for @panePassword.
  ///
  /// In en, this message translates to:
  /// **'Login Password'**
  String get panePassword;

  /// No description provided for @paneUsers.
  ///
  /// In en, this message translates to:
  /// **'Users & Groups'**
  String get paneUsers;

  /// No description provided for @paneInternetAccounts.
  ///
  /// In en, this message translates to:
  /// **'Internet Accounts'**
  String get paneInternetAccounts;

  /// No description provided for @paneKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get paneKeyboard;

  /// No description provided for @paneMouse.
  ///
  /// In en, this message translates to:
  /// **'Mouse'**
  String get paneMouse;

  /// No description provided for @panePrinters.
  ///
  /// In en, this message translates to:
  /// **'Printers & Scanners'**
  String get panePrinters;

  /// No description provided for @subAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get subAbout;

  /// No description provided for @subSoftwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software Update'**
  String get subSoftwareUpdate;

  /// No description provided for @subStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get subStorage;

  /// No description provided for @subSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get subSharing;

  /// No description provided for @subDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get subDateTime;

  /// No description provided for @subStartupDisk.
  ///
  /// In en, this message translates to:
  /// **'Startup Disk'**
  String get subStartupDisk;

  /// No description provided for @subLoginItems.
  ///
  /// In en, this message translates to:
  /// **'Login Items'**
  String get subLoginItems;

  /// No description provided for @subLanguageRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get subLanguageRegion;

  /// No description provided for @subBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get subBackups;

  /// No description provided for @subTransferReset.
  ///
  /// In en, this message translates to:
  /// **'Transfer or Reset'**
  String get subTransferReset;

  /// No description provided for @wifiNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi device found'**
  String get wifiNoDevice;

  /// No description provided for @wifiConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get wifiConnected;

  /// No description provided for @wifiKnownNetworks.
  ///
  /// In en, this message translates to:
  /// **'Known Networks'**
  String get wifiKnownNetworks;

  /// No description provided for @wifiOtherNetworks.
  ///
  /// In en, this message translates to:
  /// **'Other Networks'**
  String get wifiOtherNetworks;

  /// No description provided for @wifiConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get wifiConnect;

  /// No description provided for @wifiSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for networks…'**
  String get wifiSearching;

  /// No description provided for @wifiNoOtherNetworks.
  ///
  /// In en, this message translates to:
  /// **'No other networks'**
  String get wifiNoOtherNetworks;

  /// No description provided for @wifiNewNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Joining a new network needs its password, which Silica can\'t ask for yet. Saved networks can be joined.'**
  String get wifiNewNetworkUnavailable;

  /// No description provided for @wifiAskToJoin.
  ///
  /// In en, this message translates to:
  /// **'Ask to join networks'**
  String get wifiAskToJoin;

  /// No description provided for @wifiAskToJoinHotspots.
  ///
  /// In en, this message translates to:
  /// **'Ask to join hotspots'**
  String get wifiAskToJoinHotspots;

  /// No description provided for @wifiAskNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get wifiAskNotify;

  /// No description provided for @wifiAskNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get wifiAskNever;

  /// No description provided for @bluetoothNoAdapter.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth adapter found'**
  String get bluetoothNoAdapter;

  /// No description provided for @bluetoothMyDevices.
  ///
  /// In en, this message translates to:
  /// **'My Devices'**
  String get bluetoothMyDevices;

  /// No description provided for @bluetoothNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired devices'**
  String get bluetoothNoDevices;

  /// No description provided for @bluetoothConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get bluetoothConnected;

  /// No description provided for @bluetoothNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get bluetoothNotConnected;

  /// No description provided for @bluetoothConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get bluetoothConnect;

  /// No description provided for @bluetoothDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get bluetoothDisconnect;

  /// No description provided for @bluetoothNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby Devices'**
  String get bluetoothNearby;

  /// No description provided for @bluetoothNearbyNone.
  ///
  /// In en, this message translates to:
  /// **'Looking for devices…'**
  String get bluetoothNearbyNone;

  /// No description provided for @networkWired.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get networkWired;

  /// No description provided for @networkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get networkConnected;

  /// No description provided for @networkNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get networkNotConnected;

  /// No description provided for @networkOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get networkOff;

  /// No description provided for @networkFirewall.
  ///
  /// In en, this message translates to:
  /// **'Firewall'**
  String get networkFirewall;

  /// No description provided for @vpnNone.
  ///
  /// In en, this message translates to:
  /// **'No VPN configurations'**
  String get vpnNone;

  /// No description provided for @vpnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add VPN Configuration…'**
  String get vpnAdd;

  /// No description provided for @energyPreventSleep.
  ///
  /// In en, this message translates to:
  /// **'Keep the computer awake when the display is off'**
  String get energyPreventSleep;

  /// No description provided for @energyWakeForNetwork.
  ///
  /// In en, this message translates to:
  /// **'Wake for network access'**
  String get energyWakeForNetwork;

  /// No description provided for @energyRestartAfterPowerFailure.
  ///
  /// In en, this message translates to:
  /// **'Start up again after a power failure'**
  String get energyRestartAfterPowerFailure;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery level'**
  String get batteryLevel;

  /// No description provided for @batteryCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get batteryCharging;

  /// No description provided for @batteryOnBattery.
  ///
  /// In en, this message translates to:
  /// **'On battery'**
  String get batteryOnBattery;

  /// No description provided for @batteryLowPowerMode.
  ///
  /// In en, this message translates to:
  /// **'Low power mode'**
  String get batteryLowPowerMode;

  /// No description provided for @batteryOptimizedCharging.
  ///
  /// In en, this message translates to:
  /// **'Optimised charging'**
  String get batteryOptimizedCharging;

  /// No description provided for @generalDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage this computer: its software, storage, sharing, date, language and more.'**
  String get generalDescription;

  /// No description provided for @aboutThisComputer.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get aboutThisComputer;

  /// No description provided for @aboutName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aboutName;

  /// No description provided for @aboutProcessor.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get aboutProcessor;

  /// No description provided for @aboutMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get aboutMemory;

  /// No description provided for @aboutSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get aboutSystem;

  /// No description provided for @aboutKernel.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get aboutKernel;

  /// No description provided for @aboutDisplays.
  ///
  /// In en, this message translates to:
  /// **'Displays'**
  String get aboutDisplays;

  /// No description provided for @aboutUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get aboutUnknown;

  /// No description provided for @storageCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get storageCalculating;

  /// No description provided for @storageSystemDisk.
  ///
  /// In en, this message translates to:
  /// **'System disk'**
  String get storageSystemDisk;

  /// No description provided for @storageRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get storageRecommendations;

  /// No description provided for @storageEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty the Trash automatically'**
  String get storageEmptyTrash;

  /// No description provided for @sharingFiles.
  ///
  /// In en, this message translates to:
  /// **'File sharing'**
  String get sharingFiles;

  /// No description provided for @sharingScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen sharing'**
  String get sharingScreen;

  /// No description provided for @sharingRemoteLogin.
  ///
  /// In en, this message translates to:
  /// **'Remote login'**
  String get sharingRemoteLogin;

  /// No description provided for @sharingComputerName.
  ///
  /// In en, this message translates to:
  /// **'Computer name'**
  String get sharingComputerName;

  /// No description provided for @sharingNameReadOnly.
  ///
  /// In en, this message translates to:
  /// **'The name can\'t be changed from Settings yet.'**
  String get sharingNameReadOnly;

  /// No description provided for @dateTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get dateTimeZone;

  /// No description provided for @dateTimeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Set the date and time automatically'**
  String get dateTimeAutomatic;

  /// No description provided for @dateTime24Hour.
  ///
  /// In en, this message translates to:
  /// **'24-hour time'**
  String get dateTime24Hour;

  /// No description provided for @languagePreferred.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePreferred;

  /// No description provided for @languageReadOnly.
  ///
  /// In en, this message translates to:
  /// **'The system language can\'t be changed from Settings yet.'**
  String get languageReadOnly;

  /// No description provided for @languageRegion.
  ///
  /// In en, this message translates to:
  /// **'Region formats'**
  String get languageRegion;

  /// No description provided for @languageFirstDay.
  ///
  /// In en, this message translates to:
  /// **'First day of the week'**
  String get languageFirstDay;

  /// No description provided for @languageMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get languageMonday;

  /// No description provided for @updateInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed system'**
  String get updateInstalled;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check Now'**
  String get updateCheckButton;

  /// No description provided for @updateAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Install updates automatically'**
  String get updateAutomatic;

  /// No description provided for @accessibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Make the computer easier to see, hear and control, in the way that suits you.'**
  String get accessibilityDescription;

  /// No description provided for @accessibilityVision.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get accessibilityVision;

  /// No description provided for @accessibilityPhysical.
  ///
  /// In en, this message translates to:
  /// **'Motor'**
  String get accessibilityPhysical;

  /// No description provided for @accessibilityHearing.
  ///
  /// In en, this message translates to:
  /// **'Hearing'**
  String get accessibilityHearing;

  /// No description provided for @accessibilityScreenReader.
  ///
  /// In en, this message translates to:
  /// **'Screen reader'**
  String get accessibilityScreenReader;

  /// No description provided for @accessibilityZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get accessibilityZoom;

  /// No description provided for @accessibilityLargerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get accessibilityLargerText;

  /// No description provided for @accessibilityDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get accessibilityDisplay;

  /// No description provided for @accessibilityMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get accessibilityMotion;

  /// No description provided for @accessibilitySpokenContent.
  ///
  /// In en, this message translates to:
  /// **'Spoken content'**
  String get accessibilitySpokenContent;

  /// No description provided for @accessibilityVoiceControl.
  ///
  /// In en, this message translates to:
  /// **'Voice control'**
  String get accessibilityVoiceControl;

  /// No description provided for @accessibilityPointer.
  ///
  /// In en, this message translates to:
  /// **'Pointer control'**
  String get accessibilityPointer;

  /// No description provided for @accessibilityAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get accessibilityAudio;

  /// No description provided for @accessibilityCaptions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get accessibilityCaptions;

  /// No description provided for @appearanceMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceMode;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get appearanceAuto;

  /// No description provided for @appearanceNoDaemon.
  ///
  /// In en, this message translates to:
  /// **'The system service isn\'t running: this can\'t be changed now.'**
  String get appearanceNoDaemon;

  /// No description provided for @appearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// No description provided for @appearanceAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get appearanceAccent;

  /// No description provided for @appearanceHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight colour'**
  String get appearanceHighlight;

  /// No description provided for @appearanceIconStyle.
  ///
  /// In en, this message translates to:
  /// **'Icon and widget style'**
  String get appearanceIconStyle;

  /// No description provided for @appearanceFolderColor.
  ///
  /// In en, this message translates to:
  /// **'Folder colour'**
  String get appearanceFolderColor;

  /// No description provided for @appearanceGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get appearanceGlass;

  /// No description provided for @appearanceAutomaticChoice.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get appearanceAutomaticChoice;

  /// No description provided for @appearanceDefaultChoice.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get appearanceDefaultChoice;

  /// No description provided for @appearanceWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get appearanceWindows;

  /// No description provided for @appearanceSidebarIconSize.
  ///
  /// In en, this message translates to:
  /// **'Sidebar icon size'**
  String get appearanceSidebarIconSize;

  /// No description provided for @appearanceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get appearanceMedium;

  /// No description provided for @appearanceTint.
  ///
  /// In en, this message translates to:
  /// **'Tint windows with the wallpaper colour'**
  String get appearanceTint;

  /// No description provided for @appearanceScrollBars.
  ///
  /// In en, this message translates to:
  /// **'Show scroll bars'**
  String get appearanceScrollBars;

  /// No description provided for @appearanceScrollAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatically, depending on the pointing device'**
  String get appearanceScrollAuto;

  /// No description provided for @appearanceScrollClick.
  ///
  /// In en, this message translates to:
  /// **'Click in the scroll bar to'**
  String get appearanceScrollClick;

  /// No description provided for @appearanceScrollNextPage.
  ///
  /// In en, this message translates to:
  /// **'Jump to the next page'**
  String get appearanceScrollNextPage;

  /// No description provided for @accentMulticolour.
  ///
  /// In en, this message translates to:
  /// **'Multicolour'**
  String get accentMulticolour;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @accentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @accentRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get accentRed;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get accentYellow;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get accentGraphite;

  /// No description provided for @menuBarAutoHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the menu bar automatically'**
  String get menuBarAutoHide;

  /// No description provided for @menuBarNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get menuBarNever;

  /// No description provided for @menuBarBackground.
  ///
  /// In en, this message translates to:
  /// **'Show the menu bar background'**
  String get menuBarBackground;

  /// No description provided for @menuBarRecentItems.
  ///
  /// In en, this message translates to:
  /// **'Recent items'**
  String get menuBarRecentItems;

  /// No description provided for @menuBarControls.
  ///
  /// In en, this message translates to:
  /// **'Menu bar controls'**
  String get menuBarControls;

  /// No description provided for @menuBarShowWhenActive.
  ///
  /// In en, this message translates to:
  /// **'Show when in use'**
  String get menuBarShowWhenActive;

  /// No description provided for @displaysResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get displaysResolution;

  /// No description provided for @displaysScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get displaysScale;

  /// No description provided for @displaysRefreshRate.
  ///
  /// In en, this message translates to:
  /// **'Refresh rate'**
  String get displaysRefreshRate;

  /// No description provided for @displaysColorProfile.
  ///
  /// In en, this message translates to:
  /// **'Colour profile'**
  String get displaysColorProfile;

  /// No description provided for @displaysRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get displaysRotation;

  /// No description provided for @displaysStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get displaysStandard;

  /// No description provided for @displaysNightLight.
  ///
  /// In en, this message translates to:
  /// **'Night light'**
  String get displaysNightLight;

  /// No description provided for @displaysNightLightButton.
  ///
  /// In en, this message translates to:
  /// **'Night Light…'**
  String get displaysNightLightButton;

  /// No description provided for @dockSection.
  ///
  /// In en, this message translates to:
  /// **'Dock'**
  String get dockSection;

  /// No description provided for @dockMagnification.
  ///
  /// In en, this message translates to:
  /// **'Magnification'**
  String get dockMagnification;

  /// No description provided for @dockRecents.
  ///
  /// In en, this message translates to:
  /// **'Show suggested and recent apps'**
  String get dockRecents;

  /// No description provided for @dockRestartNote.
  ///
  /// In en, this message translates to:
  /// **'The Dock reads these choices when the session starts.'**
  String get dockRestartNote;

  /// No description provided for @dockSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get dockSize;

  /// No description provided for @dockPosition.
  ///
  /// In en, this message translates to:
  /// **'Position on screen'**
  String get dockPosition;

  /// No description provided for @dockBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get dockBottom;

  /// No description provided for @dockMinimizeEffect.
  ///
  /// In en, this message translates to:
  /// **'Minimise windows using'**
  String get dockMinimizeEffect;

  /// No description provided for @dockGenie.
  ///
  /// In en, this message translates to:
  /// **'Genie effect'**
  String get dockGenie;

  /// No description provided for @dockDoubleClick.
  ///
  /// In en, this message translates to:
  /// **'Double-click a title bar to'**
  String get dockDoubleClick;

  /// No description provided for @dockZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get dockZoom;

  /// No description provided for @dockMinimiseAction.
  ///
  /// In en, this message translates to:
  /// **'Minimise'**
  String get dockMinimiseAction;

  /// No description provided for @dockDoubleClickNothing.
  ///
  /// In en, this message translates to:
  /// **'Do nothing'**
  String get dockDoubleClickNothing;

  /// No description provided for @dockMinimizeIntoIcon.
  ///
  /// In en, this message translates to:
  /// **'Minimise windows into the app icon'**
  String get dockMinimizeIntoIcon;

  /// No description provided for @dockAutoHide.
  ///
  /// In en, this message translates to:
  /// **'Hide and show the Dock automatically'**
  String get dockAutoHide;

  /// No description provided for @dockAnimate.
  ///
  /// In en, this message translates to:
  /// **'Animate opening apps'**
  String get dockAnimate;

  /// No description provided for @dockIndicators.
  ///
  /// In en, this message translates to:
  /// **'Show indicators for open apps'**
  String get dockIndicators;

  /// No description provided for @dockShortcutsButton.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts…'**
  String get dockShortcutsButton;

  /// No description provided for @dockHotCorners.
  ///
  /// In en, this message translates to:
  /// **'Hot Corners…'**
  String get dockHotCorners;

  /// No description provided for @desktopSection.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get desktopSection;

  /// No description provided for @desktopClickWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Click the wallpaper to show the desktop'**
  String get desktopClickWallpaper;

  /// No description provided for @desktopOnlyInStage.
  ///
  /// In en, this message translates to:
  /// **'Only in stage view'**
  String get desktopOnlyInStage;

  /// No description provided for @desktopStage.
  ///
  /// In en, this message translates to:
  /// **'Stage view'**
  String get desktopStage;

  /// No description provided for @panoramaSection.
  ///
  /// In en, this message translates to:
  /// **'Panorama'**
  String get panoramaSection;

  /// No description provided for @panoramaRearrange.
  ///
  /// In en, this message translates to:
  /// **'Rearrange spaces by most recent use'**
  String get panoramaRearrange;

  /// No description provided for @panoramaSwitchToApp.
  ///
  /// In en, this message translates to:
  /// **'Switch to a space with the app\'s windows'**
  String get panoramaSwitchToApp;

  /// No description provided for @panoramaGroupByApp.
  ///
  /// In en, this message translates to:
  /// **'Group windows by app'**
  String get panoramaGroupByApp;

  /// No description provided for @panoramaSeparateSpaces.
  ///
  /// In en, this message translates to:
  /// **'Displays have separate spaces'**
  String get panoramaSeparateSpaces;

  /// No description provided for @hotCornerNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get hotCornerNone;

  /// No description provided for @wallpaperFill.
  ///
  /// In en, this message translates to:
  /// **'Fill screen'**
  String get wallpaperFill;

  /// No description provided for @wallpaperSilica.
  ///
  /// In en, this message translates to:
  /// **'Silica'**
  String get wallpaperSilica;

  /// No description provided for @wallpaperAmalfi.
  ///
  /// In en, this message translates to:
  /// **'Amalfi'**
  String get wallpaperAmalfi;

  /// No description provided for @wallpaperSilicaName.
  ///
  /// In en, this message translates to:
  /// **'Silica'**
  String get wallpaperSilicaName;

  /// No description provided for @wallpaperColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get wallpaperColors;

  /// No description provided for @wallpaperPictures.
  ///
  /// In en, this message translates to:
  /// **'Your Pictures'**
  String get wallpaperPictures;

  /// No description provided for @wallpaperScreenSaver.
  ///
  /// In en, this message translates to:
  /// **'Screen Saver…'**
  String get wallpaperScreenSaver;

  /// No description provided for @searchDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what Faro, the search panel, looks through.'**
  String get searchDescription;

  /// No description provided for @searchHelpImprove.
  ///
  /// In en, this message translates to:
  /// **'Help improve search'**
  String get searchHelpImprove;

  /// No description provided for @searchShowRelated.
  ///
  /// In en, this message translates to:
  /// **'Show related content'**
  String get searchShowRelated;

  /// No description provided for @searchResultsFromApps.
  ///
  /// In en, this message translates to:
  /// **'Results from apps'**
  String get searchResultsFromApps;

  /// No description provided for @searchApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get searchApplications;

  /// No description provided for @searchFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get searchFolders;

  /// No description provided for @searchCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculations and conversions'**
  String get searchCalculator;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how apps can get your attention.'**
  String get notificationsDescription;

  /// No description provided for @notificationsCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationsCenter;

  /// No description provided for @notificationsPreviews.
  ///
  /// In en, this message translates to:
  /// **'Show previews'**
  String get notificationsPreviews;

  /// No description provided for @notificationsWhenUnlocked.
  ///
  /// In en, this message translates to:
  /// **'When unlocked'**
  String get notificationsWhenUnlocked;

  /// No description provided for @notificationsWhenSleeping.
  ///
  /// In en, this message translates to:
  /// **'while the display sleeps'**
  String get notificationsWhenSleeping;

  /// No description provided for @notificationsWhenLocked.
  ///
  /// In en, this message translates to:
  /// **'while the screen is locked'**
  String get notificationsWhenLocked;

  /// No description provided for @notificationsWhenMirroring.
  ///
  /// In en, this message translates to:
  /// **'while the screen is mirrored or shared'**
  String get notificationsWhenMirroring;

  /// No description provided for @notificationsApps.
  ///
  /// In en, this message translates to:
  /// **'Application notifications'**
  String get notificationsApps;

  /// No description provided for @notificationsAppsNone.
  ///
  /// In en, this message translates to:
  /// **'No apps have sent notifications'**
  String get notificationsAppsNone;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @soundAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert sound'**
  String get soundAlert;

  /// No description provided for @soundAlertVolume.
  ///
  /// In en, this message translates to:
  /// **'Alert volume'**
  String get soundAlertVolume;

  /// No description provided for @soundStartup.
  ///
  /// In en, this message translates to:
  /// **'Play a sound at startup'**
  String get soundStartup;

  /// No description provided for @soundInterface.
  ///
  /// In en, this message translates to:
  /// **'Play interface sound effects'**
  String get soundInterface;

  /// No description provided for @soundVolumeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when the volume changes'**
  String get soundVolumeFeedback;

  /// No description provided for @soundOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get soundOutput;

  /// No description provided for @soundOutputDevice.
  ///
  /// In en, this message translates to:
  /// **'Output device'**
  String get soundOutputDevice;

  /// No description provided for @soundNoAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio service found.'**
  String get soundNoAudio;

  /// No description provided for @soundOutputVolume.
  ///
  /// In en, this message translates to:
  /// **'Output volume'**
  String get soundOutputVolume;

  /// No description provided for @soundMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get soundMute;

  /// No description provided for @soundInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get soundInput;

  /// No description provided for @soundInputLevel.
  ///
  /// In en, this message translates to:
  /// **'Input volume'**
  String get soundInputLevel;

  /// No description provided for @focusDoNotDisturb.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get focusDoNotDisturb;

  /// No description provided for @focusStatus.
  ///
  /// In en, this message translates to:
  /// **'Focus status'**
  String get focusStatus;

  /// No description provided for @screenTimeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get screenTimeActivity;

  /// No description provided for @screenTimeAppUsage.
  ///
  /// In en, this message translates to:
  /// **'App and website activity'**
  String get screenTimeAppUsage;

  /// No description provided for @screenTimeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get screenTimeNotifications;

  /// No description provided for @screenTimeLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get screenTimeLimits;

  /// No description provided for @screenTimeDowntime.
  ///
  /// In en, this message translates to:
  /// **'Downtime'**
  String get screenTimeDowntime;

  /// No description provided for @screenTimeAppLimits.
  ///
  /// In en, this message translates to:
  /// **'App limits'**
  String get screenTimeAppLimits;

  /// No description provided for @screenTimeAppActivity.
  ///
  /// In en, this message translates to:
  /// **'Share app and website activity'**
  String get screenTimeAppActivity;

  /// No description provided for @lockDisplayOff.
  ///
  /// In en, this message translates to:
  /// **'Turn the display off when inactive'**
  String get lockDisplayOff;

  /// No description provided for @lockPasswordDelay.
  ///
  /// In en, this message translates to:
  /// **'Require password after sleep or screen saver'**
  String get lockPasswordDelay;

  /// No description provided for @lockSavedForLater.
  ///
  /// In en, this message translates to:
  /// **'Silica has no lock screen yet: these choices are saved for it.'**
  String get lockSavedForLater;

  /// No description provided for @lockNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get lockNever;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockShowUser.
  ///
  /// In en, this message translates to:
  /// **'Show user name and photo'**
  String get lockShowUser;

  /// No description provided for @lockShowHints.
  ///
  /// In en, this message translates to:
  /// **'Show password hints'**
  String get lockShowHints;

  /// No description provided for @lockShowMessage.
  ///
  /// In en, this message translates to:
  /// **'Show a message when locked'**
  String get lockShowMessage;

  /// No description provided for @lockLoginWindowShows.
  ///
  /// In en, this message translates to:
  /// **'Login window shows'**
  String get lockLoginWindowShows;

  /// No description provided for @lockListOfUsers.
  ///
  /// In en, this message translates to:
  /// **'List of users'**
  String get lockListOfUsers;

  /// No description provided for @lockNameAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Name and password'**
  String get lockNameAndPassword;

  /// No description provided for @lockShowPowerButtons.
  ///
  /// In en, this message translates to:
  /// **'Show the sleep, restart and shut down buttons'**
  String get lockShowPowerButtons;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Control which apps can use your location, camera, microphone and files.'**
  String get privacyDescription;

  /// No description provided for @privacyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get privacyLocation;

  /// No description provided for @privacyCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get privacyCamera;

  /// No description provided for @privacyMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get privacyMicrophone;

  /// No description provided for @privacyScreenRecording.
  ///
  /// In en, this message translates to:
  /// **'Screen recording'**
  String get privacyScreenRecording;

  /// No description provided for @privacyFiles.
  ///
  /// In en, this message translates to:
  /// **'Files and folders'**
  String get privacyFiles;

  /// No description provided for @passwordLogin.
  ///
  /// In en, this message translates to:
  /// **'Login password'**
  String get passwordLogin;

  /// No description provided for @passwordSet.
  ///
  /// In en, this message translates to:
  /// **'A password is set for your account'**
  String get passwordSet;

  /// No description provided for @passwordChange.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get passwordChange;

  /// No description provided for @passwordFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use a fingerprint to unlock'**
  String get passwordFingerprint;

  /// No description provided for @usersAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get usersAdmin;

  /// No description provided for @usersYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get usersYou;

  /// No description provided for @usersGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get usersGuest;

  /// No description provided for @usersAutomaticLogin.
  ///
  /// In en, this message translates to:
  /// **'Automatically log in as'**
  String get usersAutomaticLogin;

  /// No description provided for @usersAddGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group…'**
  String get usersAddGroup;

  /// No description provided for @usersAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add User…'**
  String get usersAddUser;

  /// No description provided for @accountsNone.
  ///
  /// In en, this message translates to:
  /// **'No internet accounts'**
  String get accountsNone;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Account…'**
  String get accountsAdd;

  /// No description provided for @keyboardRepeatRate.
  ///
  /// In en, this message translates to:
  /// **'Key repeat rate'**
  String get keyboardRepeatRate;

  /// No description provided for @keyboardRepeatDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay until repeat'**
  String get keyboardRepeatDelay;

  /// No description provided for @keyboardRepeatNote.
  ///
  /// In en, this message translates to:
  /// **'Ossido applies these to the keys held down in every app.'**
  String get keyboardRepeatNote;

  /// No description provided for @keyboardOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get keyboardOff;

  /// No description provided for @keyboardSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get keyboardSlow;

  /// No description provided for @keyboardFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get keyboardFast;

  /// No description provided for @keyboardLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get keyboardLong;

  /// No description provided for @keyboardShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get keyboardShort;

  /// No description provided for @keyboardGlobeKey.
  ///
  /// In en, this message translates to:
  /// **'Press the function key to'**
  String get keyboardGlobeKey;

  /// No description provided for @keyboardDoNothing.
  ///
  /// In en, this message translates to:
  /// **'Do nothing'**
  String get keyboardDoNothing;

  /// No description provided for @keyboardNavigation.
  ///
  /// In en, this message translates to:
  /// **'Keyboard navigation'**
  String get keyboardNavigation;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @keyboardShortcutsButton.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts…'**
  String get keyboardShortcutsButton;

  /// No description provided for @keyboardTextInput.
  ///
  /// In en, this message translates to:
  /// **'Text input'**
  String get keyboardTextInput;

  /// No description provided for @keyboardInputSources.
  ///
  /// In en, this message translates to:
  /// **'Input sources'**
  String get keyboardInputSources;

  /// No description provided for @keyboardTextReplacements.
  ///
  /// In en, this message translates to:
  /// **'Text replacements'**
  String get keyboardTextReplacements;

  /// No description provided for @keyboardDictation.
  ///
  /// In en, this message translates to:
  /// **'Dictation'**
  String get keyboardDictation;

  /// No description provided for @shortcutsScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get shortcutsScreenshots;

  /// No description provided for @shortcutsSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces and Panorama'**
  String get shortcutsSpaces;

  /// No description provided for @shortcutsApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get shortcutsApps;

  /// No description provided for @shortcutsWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get shortcutsWindows;

  /// No description provided for @shortcutsSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get shortcutsSession;

  /// No description provided for @shortcutScreen.
  ///
  /// In en, this message translates to:
  /// **'Picture of the whole screen'**
  String get shortcutScreen;

  /// No description provided for @shortcutSelection.
  ///
  /// In en, this message translates to:
  /// **'Picture of a selected area'**
  String get shortcutSelection;

  /// No description provided for @shortcutTools.
  ///
  /// In en, this message translates to:
  /// **'Screenshot and recording tools'**
  String get shortcutTools;

  /// No description provided for @shortcutPanorama.
  ///
  /// In en, this message translates to:
  /// **'Show Panorama'**
  String get shortcutPanorama;

  /// No description provided for @shortcutAppWindows.
  ///
  /// In en, this message translates to:
  /// **'Show the app\'s windows'**
  String get shortcutAppWindows;

  /// No description provided for @shortcutShowDesktop.
  ///
  /// In en, this message translates to:
  /// **'Show the desktop'**
  String get shortcutShowDesktop;

  /// No description provided for @shortcutPreviousSpace.
  ///
  /// In en, this message translates to:
  /// **'Previous space'**
  String get shortcutPreviousSpace;

  /// No description provided for @shortcutNextSpace.
  ///
  /// In en, this message translates to:
  /// **'Next space'**
  String get shortcutNextSpace;

  /// No description provided for @shortcutSearch.
  ///
  /// In en, this message translates to:
  /// **'Open Faro'**
  String get shortcutSearch;

  /// No description provided for @shortcutNextApp.
  ///
  /// In en, this message translates to:
  /// **'Next app'**
  String get shortcutNextApp;

  /// No description provided for @shortcutPreviousApp.
  ///
  /// In en, this message translates to:
  /// **'Previous app'**
  String get shortcutPreviousApp;

  /// No description provided for @shortcutQuitApp.
  ///
  /// In en, this message translates to:
  /// **'Quit the app'**
  String get shortcutQuitApp;

  /// No description provided for @shortcutForceQuit.
  ///
  /// In en, this message translates to:
  /// **'Force quit'**
  String get shortcutForceQuit;

  /// No description provided for @shortcutCloseWindow.
  ///
  /// In en, this message translates to:
  /// **'Close the window'**
  String get shortcutCloseWindow;

  /// No description provided for @shortcutMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimise the window'**
  String get shortcutMinimize;

  /// No description provided for @shortcutFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get shortcutFullScreen;

  /// No description provided for @shortcutLogOut.
  ///
  /// In en, this message translates to:
  /// **'End the session'**
  String get shortcutLogOut;

  /// No description provided for @mousePointerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Pointer speed'**
  String get mousePointerSpeed;

  /// No description provided for @mouseNaturalScrolling.
  ///
  /// In en, this message translates to:
  /// **'Natural scrolling'**
  String get mouseNaturalScrolling;

  /// No description provided for @mouseSecondaryClick.
  ///
  /// In en, this message translates to:
  /// **'Secondary click'**
  String get mouseSecondaryClick;

  /// No description provided for @mouseRightButton.
  ///
  /// In en, this message translates to:
  /// **'Right button'**
  String get mouseRightButton;

  /// No description provided for @mouseDoubleClickSpeed.
  ///
  /// In en, this message translates to:
  /// **'Double-click speed'**
  String get mouseDoubleClickSpeed;

  /// No description provided for @mouseScrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Scrolling speed'**
  String get mouseScrollSpeed;

  /// No description provided for @printersDefault.
  ///
  /// In en, this message translates to:
  /// **'Default printer'**
  String get printersDefault;

  /// No description provided for @printersLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last printer used'**
  String get printersLastUsed;

  /// No description provided for @printersPaperSize.
  ///
  /// In en, this message translates to:
  /// **'Default paper size'**
  String get printersPaperSize;

  /// No description provided for @printersNone.
  ///
  /// In en, this message translates to:
  /// **'No printers'**
  String get printersNone;

  /// No description provided for @printersIsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get printersIsDefault;

  /// No description provided for @printersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Printer…'**
  String get printersAdd;

  /// No description provided for @aboutDisplayN.
  ///
  /// In en, this message translates to:
  /// **'Display {number}'**
  String aboutDisplayN(int number);

  /// No description provided for @aboutProcessorCount.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count} cores)'**
  String aboutProcessorCount(String name, int count);

  /// No description provided for @storageAvailableOf.
  ///
  /// In en, this message translates to:
  /// **'{available} available of {total}'**
  String storageAvailableOf(String available, String total);

  /// No description provided for @lockMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String lockMinutes(int count);

  /// No description provided for @lockHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String lockHours(int count);

  /// No description provided for @lockSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String lockSeconds(int count);

  /// No description provided for @appearanceOtherApps.
  ///
  /// In en, this message translates to:
  /// **'The apps and the desktop follow this at once.'**
  String get appearanceOtherApps;

  /// No description provided for @appearanceNoTintYet.
  ///
  /// In en, this message translates to:
  /// **'Tinting windows with the wallpaper colour is not available yet.'**
  String get appearanceNoTintYet;

  /// No description provided for @appearanceThemeNote.
  ///
  /// In en, this message translates to:
  /// **'The apps and the desktop follow this at once. Folder colours are not available yet.'**
  String get appearanceThemeNote;

  /// No description provided for @wallpaperFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to screen'**
  String get wallpaperFit;

  /// No description provided for @wallpaperStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch to fill screen'**
  String get wallpaperStretch;

  /// No description provided for @wallpaperCenter.
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get wallpaperCenter;

  /// No description provided for @wallpaperTile.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get wallpaperTile;

  /// No description provided for @notificationsPreviewsAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get notificationsPreviewsAlways;

  /// No description provided for @notificationsPreviewsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get notificationsPreviewsNever;

  /// No description provided for @notificationsPreviewsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notificationsPreviewsDefault;

  /// No description provided for @notificationsGroupByApp.
  ///
  /// In en, this message translates to:
  /// **'By app'**
  String get notificationsGroupByApp;

  /// No description provided for @notificationsInCenter.
  ///
  /// In en, this message translates to:
  /// **'Show in Notification Center'**
  String get notificationsInCenter;

  /// No description provided for @menuBarRecentNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get menuBarRecentNone;

  /// No description provided for @dateTimeMenuBarClock.
  ///
  /// In en, this message translates to:
  /// **'Menu bar clock'**
  String get dateTimeMenuBarClock;

  /// No description provided for @dateTimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get dateTimeSeconds;

  /// No description provided for @dateTimeWeekday.
  ///
  /// In en, this message translates to:
  /// **'Show the day of the week'**
  String get dateTimeWeekday;

  /// No description provided for @dateTimeDate.
  ///
  /// In en, this message translates to:
  /// **'Show the date'**
  String get dateTimeDate;

  /// No description provided for @dateTimeDateAuto.
  ///
  /// In en, this message translates to:
  /// **'When space allows'**
  String get dateTimeDateAuto;

  /// No description provided for @dateTimeDateAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get dateTimeDateAlways;

  /// No description provided for @dateTimeDateNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get dateTimeDateNever;

  /// No description provided for @dateTimeClockHelp.
  ///
  /// In en, this message translates to:
  /// **'The clock in the menu bar changes at once.'**
  String get dateTimeClockHelp;

  /// No description provided for @energyWakeForNetworkHelp.
  ///
  /// In en, this message translates to:
  /// **'The computer wakes when a network message addresses it. It takes effect when the wired connection is next connected.'**
  String get energyWakeForNetworkHelp;

  /// No description provided for @energyWakeForNetworkNone.
  ///
  /// In en, this message translates to:
  /// **'There is no saved wired connection.'**
  String get energyWakeForNetworkNone;

  /// No description provided for @keyboardNavigationHelp.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to move between all the controls of a window.'**
  String get keyboardNavigationHelp;

  /// No description provided for @mouseDoubleClickHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies to the apps and the desktop at once.'**
  String get mouseDoubleClickHelp;

  /// No description provided for @accessibilityMoreVision.
  ///
  /// In en, this message translates to:
  /// **'More vision options'**
  String get accessibilityMoreVision;

  /// No description provided for @accessibilityReduceTransparency.
  ///
  /// In en, this message translates to:
  /// **'Reduce transparency'**
  String get accessibilityReduceTransparency;

  /// No description provided for @accessibilityReduceTransparencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Windows, menus and the Dock are drawn without see-through glass.'**
  String get accessibilityReduceTransparencyHelp;

  /// No description provided for @accessibilityIncreaseContrast.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast'**
  String get accessibilityIncreaseContrast;

  /// No description provided for @accessibilityReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get accessibilityReduceMotion;

  /// No description provided for @accessibilityReduceMotionHelp.
  ///
  /// In en, this message translates to:
  /// **'Windows and menus move less: the desktop skips its animations and apps are told to do the same.'**
  String get accessibilityReduceMotionHelp;

  /// No description provided for @hotCornerPanorama.
  ///
  /// In en, this message translates to:
  /// **'Panorama'**
  String get hotCornerPanorama;

  /// No description provided for @hotCornerAppWindows.
  ///
  /// In en, this message translates to:
  /// **'Application windows'**
  String get hotCornerAppWindows;

  /// No description provided for @hotCornerDesktop.
  ///
  /// In en, this message translates to:
  /// **'Show desktop'**
  String get hotCornerDesktop;

  /// No description provided for @hotCornerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get hotCornerNotifications;

  /// No description provided for @hotCornerLauncher.
  ///
  /// In en, this message translates to:
  /// **'Launcher'**
  String get hotCornerLauncher;

  /// No description provided for @hotCornerControlCenter.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get hotCornerControlCenter;

  /// No description provided for @hotCornerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get hotCornerSearch;

  /// No description provided for @hotCornersHelp.
  ///
  /// In en, this message translates to:
  /// **'Move the pointer into the corner of the screen to run the action.'**
  String get hotCornersHelp;

  /// No description provided for @appearanceGlassClear.
  ///
  /// In en, this message translates to:
  /// **'Clearer'**
  String get appearanceGlassClear;

  /// No description provided for @appearanceGlassTinted.
  ///
  /// In en, this message translates to:
  /// **'More tinted'**
  String get appearanceGlassTinted;

  /// No description provided for @appearanceStyleDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get appearanceStyleDefault;

  /// No description provided for @appearanceStyleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceStyleDark;

  /// No description provided for @appearanceStyleClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get appearanceStyleClear;

  /// No description provided for @appearanceStyleTinted.
  ///
  /// In en, this message translates to:
  /// **'Tinted'**
  String get appearanceStyleTinted;

  /// No description provided for @appearanceSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get appearanceSmall;

  /// No description provided for @appearanceLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get appearanceLarge;

  /// No description provided for @appearanceScrollWhenScrolling.
  ///
  /// In en, this message translates to:
  /// **'While scrolling'**
  String get appearanceScrollWhenScrolling;

  /// No description provided for @appearanceScrollAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get appearanceScrollAlways;

  /// No description provided for @appearanceScrollSpot.
  ///
  /// In en, this message translates to:
  /// **'Jump to the spot that\'s clicked'**
  String get appearanceScrollSpot;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add…'**
  String get addButton;

  /// No description provided for @detailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details…'**
  String get detailsButton;

  /// No description provided for @moreFor.
  ///
  /// In en, this message translates to:
  /// **'More for {name}'**
  String moreFor(String name);

  /// No description provided for @errorMissing.
  ///
  /// In en, this message translates to:
  /// **'The service this needs isn\'t installed on this system.'**
  String get errorMissing;

  /// No description provided for @errorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'The system wants an administrator\'s password for this, and Silica can\'t ask for it yet.'**
  String get errorAuthentication;

  /// No description provided for @errorRefused.
  ///
  /// In en, this message translates to:
  /// **'The system refused the change: {detail}'**
  String errorRefused(String detail);

  /// No description provided for @errorFailed.
  ///
  /// In en, this message translates to:
  /// **'The change didn\'t go through: {detail}'**
  String errorFailed(String detail);

  /// No description provided for @wifiDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet without a cable. Turn Wi-Fi on, then choose a network.'**
  String get wifiDescription;

  /// No description provided for @wifiDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get wifiDisconnect;

  /// No description provided for @wifiAutoJoin.
  ///
  /// In en, this message translates to:
  /// **'Join Automatically'**
  String get wifiAutoJoin;

  /// No description provided for @wifiAutoJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join this network automatically'**
  String get wifiAutoJoinTitle;

  /// No description provided for @wifiForget.
  ///
  /// In en, this message translates to:
  /// **'Forget This Network…'**
  String get wifiForget;

  /// No description provided for @wifiOther.
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get wifiOther;

  /// No description provided for @wifiAskToJoinHelp.
  ///
  /// In en, this message translates to:
  /// **'Known networks are joined automatically. Without one, Silica tells you which networks are around.'**
  String get wifiAskToJoinHelp;

  /// No description provided for @wifiAskToJoinHotspotsHelp.
  ///
  /// In en, this message translates to:
  /// **'Lets Silica find a phone\'s hotspot nearby when no Wi-Fi network is around.'**
  String get wifiAskToJoinHotspotsHelp;

  /// No description provided for @wifiAskAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get wifiAskAsk;

  /// No description provided for @wifiJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join “{ssid}”'**
  String wifiJoinTitle(String ssid);

  /// No description provided for @wifiJoinHidden.
  ///
  /// In en, this message translates to:
  /// **'Join a hidden network'**
  String get wifiJoinHidden;

  /// No description provided for @wifiJoinHelp.
  ///
  /// In en, this message translates to:
  /// **'Type the network\'s password. Silica keeps it for the next time.'**
  String get wifiJoinHelp;

  /// No description provided for @wifiNetworkName.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get wifiNetworkName;

  /// No description provided for @wifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wifiPassword;

  /// No description provided for @wifiWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The network didn\'t accept the password.'**
  String get wifiWrongPassword;

  /// No description provided for @wifiJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get wifiJoin;

  /// No description provided for @networkIpAddress.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get networkIpAddress;

  /// No description provided for @networkRouter.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get networkRouter;

  /// No description provided for @networkDns.
  ///
  /// In en, this message translates to:
  /// **'DNS servers'**
  String get networkDns;

  /// No description provided for @networkIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv6 address'**
  String get networkIpv6;

  /// No description provided for @networkHardwareAddress.
  ///
  /// In en, this message translates to:
  /// **'Hardware address'**
  String get networkHardwareAddress;

  /// No description provided for @networkInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get networkInterface;

  /// No description provided for @networkBridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get networkBridge;

  /// No description provided for @networkCellular.
  ///
  /// In en, this message translates to:
  /// **'Cellular'**
  String get networkCellular;

  /// No description provided for @networkNoServices.
  ///
  /// In en, this message translates to:
  /// **'No network services'**
  String get networkNoServices;

  /// No description provided for @networkUnplugged.
  ///
  /// In en, this message translates to:
  /// **'Cable unplugged'**
  String get networkUnplugged;

  /// No description provided for @networkDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get networkDisconnect;

  /// No description provided for @bluetoothDescription.
  ///
  /// In en, this message translates to:
  /// **'Use wireless headphones, keyboards, mice and other devices.'**
  String get bluetoothDescription;

  /// No description provided for @bluetoothForget.
  ///
  /// In en, this message translates to:
  /// **'Forget This Device…'**
  String get bluetoothForget;

  /// No description provided for @bluetoothPinNote.
  ///
  /// In en, this message translates to:
  /// **'Devices that ask for a PIN or a code can\'t be paired yet.'**
  String get bluetoothPinNote;

  /// No description provided for @notificationsCenterHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications collect in the Notification Center at the top right of the screen. Click the clock in the menu bar to show or hide it.'**
  String get notificationsCenterHelp;

  /// No description provided for @notificationsShowWhen.
  ///
  /// In en, this message translates to:
  /// **'Show notifications:'**
  String get notificationsShowWhen;

  /// No description provided for @notificationsAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Apps appear here once they send a notification.'**
  String get notificationsAppsHelp;

  /// No description provided for @notificationsStyleBanners.
  ///
  /// In en, this message translates to:
  /// **'Banners'**
  String get notificationsStyleBanners;

  /// No description provided for @notificationsStyleAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notificationsStyleAlerts;

  /// No description provided for @notificationsStyleOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationsStyleOff;

  /// No description provided for @notificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notificationsAllow;

  /// No description provided for @notificationsAlertStyle.
  ///
  /// In en, this message translates to:
  /// **'Banner style'**
  String get notificationsAlertStyle;

  /// No description provided for @notificationsStyleTemporary.
  ///
  /// In en, this message translates to:
  /// **'Leave by themselves'**
  String get notificationsStyleTemporary;

  /// No description provided for @notificationsStylePersistent.
  ///
  /// In en, this message translates to:
  /// **'Stay until dismissed'**
  String get notificationsStylePersistent;

  /// No description provided for @notificationsStyleHelp.
  ///
  /// In en, this message translates to:
  /// **'Banners that leave by themselves go away after a few seconds; the others stay on screen until you act on them.'**
  String get notificationsStyleHelp;

  /// No description provided for @notificationsBadges.
  ///
  /// In en, this message translates to:
  /// **'Badge app icon'**
  String get notificationsBadges;

  /// No description provided for @notificationsSound.
  ///
  /// In en, this message translates to:
  /// **'Play a sound'**
  String get notificationsSound;

  /// No description provided for @notificationsGrouping.
  ///
  /// In en, this message translates to:
  /// **'Group notifications'**
  String get notificationsGrouping;

  /// No description provided for @soundEffectsThrough.
  ///
  /// In en, this message translates to:
  /// **'Play sound effects through'**
  String get soundEffectsThrough;

  /// No description provided for @soundSelectedOutput.
  ///
  /// In en, this message translates to:
  /// **'Selected output device'**
  String get soundSelectedOutput;

  /// No description provided for @soundOutputInput.
  ///
  /// In en, this message translates to:
  /// **'Output and input'**
  String get soundOutputInput;

  /// No description provided for @soundName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get soundName;

  /// No description provided for @soundType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get soundType;

  /// No description provided for @soundNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get soundNoDevices;

  /// No description provided for @soundBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get soundBuiltIn;

  /// No description provided for @soundVirtual.
  ///
  /// In en, this message translates to:
  /// **'Virtual'**
  String get soundVirtual;

  /// No description provided for @soundInputVolume.
  ///
  /// In en, this message translates to:
  /// **'Input volume'**
  String get soundInputVolume;

  /// No description provided for @focusDoNotDisturbHelp.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb keeps notifications in the Notification Center without banners or sounds.'**
  String get focusDoNotDisturbHelp;

  /// No description provided for @menuBarInFullScreen.
  ///
  /// In en, this message translates to:
  /// **'In full screen only'**
  String get menuBarInFullScreen;

  /// No description provided for @menuBarControlsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose which status items the menu bar shows.'**
  String get menuBarControlsHelp;

  /// No description provided for @menuBarLive.
  ///
  /// In en, this message translates to:
  /// **'The menu bar changes at once.'**
  String get menuBarLive;

  /// No description provided for @menuBarAlways.
  ///
  /// In en, this message translates to:
  /// **'Always show'**
  String get menuBarAlways;

  /// No description provided for @menuBarBatteryPercent.
  ///
  /// In en, this message translates to:
  /// **'Show the percentage'**
  String get menuBarBatteryPercent;

  /// No description provided for @displaysNone.
  ///
  /// In en, this message translates to:
  /// **'No connected display found'**
  String get displaysNone;

  /// No description provided for @displaysModesHelp.
  ///
  /// In en, this message translates to:
  /// **'The modes this display offers.'**
  String get displaysModesHelp;

  /// No description provided for @displaysUseAs.
  ///
  /// In en, this message translates to:
  /// **'Use as'**
  String get displaysUseAs;

  /// No description provided for @displaysMain.
  ///
  /// In en, this message translates to:
  /// **'Main display'**
  String get displaysMain;

  /// No description provided for @displaysDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'{mode} (native)'**
  String displaysDefaultMode(String mode);

  /// No description provided for @displaysNow.
  ///
  /// In en, this message translates to:
  /// **'What the display shows now.'**
  String get displaysNow;

  /// No description provided for @dockSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get dockSmall;

  /// No description provided for @dockLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get dockLarge;

  /// No description provided for @dockMagnificationSize.
  ///
  /// In en, this message translates to:
  /// **'Magnification size'**
  String get dockMagnificationSize;

  /// No description provided for @dockLiveNote.
  ///
  /// In en, this message translates to:
  /// **'The Dock changes at once. The side positions and minimizing into the app icon wait for the shell.'**
  String get dockLiveNote;

  /// No description provided for @dockLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get dockLeft;

  /// No description provided for @dockRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get dockRight;

  /// No description provided for @dockScale.
  ///
  /// In en, this message translates to:
  /// **'Scale effect'**
  String get dockScale;

  /// No description provided for @desktopDefaultBrowser.
  ///
  /// In en, this message translates to:
  /// **'Default web browser'**
  String get desktopDefaultBrowser;

  /// No description provided for @wallpaperAllSpaces.
  ///
  /// In en, this message translates to:
  /// **'Show on all spaces'**
  String get wallpaperAllSpaces;

  /// No description provided for @wallpaperNote.
  ///
  /// In en, this message translates to:
  /// **'The desktop changes at once.'**
  String get wallpaperNote;

  /// No description provided for @wallpaperShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String wallpaperShowAll(int count);

  /// No description provided for @wallpaperShowFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get wallpaperShowFewer;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get changeButton;

  /// No description provided for @aboutFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware {version}'**
  String aboutFirmware(String version);

  /// No description provided for @aboutGraphics.
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get aboutGraphics;

  /// No description provided for @aboutSoftware.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get aboutSoftware;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @storageDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get storageDocuments;

  /// No description provided for @storageDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get storageDownloads;

  /// No description provided for @storagePictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get storagePictures;

  /// No description provided for @storageMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get storageMusic;

  /// No description provided for @storageVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get storageVideos;

  /// No description provided for @storageTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get storageTrash;

  /// No description provided for @storageEmptyTrashButton.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get storageEmptyTrashButton;

  /// No description provided for @storageEmptyTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty the Trash?'**
  String get storageEmptyTrashTitle;

  /// No description provided for @storageEmptyTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'The items in the Trash are deleted for good. This can\'t be undone.'**
  String get storageEmptyTrashMessage;

  /// No description provided for @storageEmptyTrashFailed.
  ///
  /// In en, this message translates to:
  /// **'Some items couldn\'t be deleted.'**
  String get storageEmptyTrashFailed;

  /// No description provided for @sharingServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get sharingServices;

  /// No description provided for @sharingNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Other computers on the local network see this computer as “{host}.local”.'**
  String sharingNameHelp(String host);

  /// No description provided for @sharingRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get sharingRename;

  /// No description provided for @dateTimeSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Synchronized with a time server'**
  String get dateTimeSynchronized;

  /// No description provided for @dateTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateTimeNow;

  /// No description provided for @dateTimeChooseZone.
  ///
  /// In en, this message translates to:
  /// **'Choose a time zone'**
  String get dateTimeChooseZone;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// No description provided for @languageRegionHelp.
  ///
  /// In en, this message translates to:
  /// **'Dates, times, numbers, currency and measures'**
  String get languageRegionHelp;

  /// No description provided for @languageNextLogin.
  ///
  /// In en, this message translates to:
  /// **'Apps use a new language and formats from the next login.'**
  String get languageNextLogin;

  /// No description provided for @languageChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose the system language'**
  String get languageChooseLanguage;

  /// No description provided for @languageChooseRegion.
  ///
  /// In en, this message translates to:
  /// **'Choose the formats'**
  String get languageChooseRegion;

  /// No description provided for @powerMode.
  ///
  /// In en, this message translates to:
  /// **'Power mode'**
  String get powerMode;

  /// No description provided for @powerModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Balance speed against power use and heat.'**
  String get powerModeHelp;

  /// No description provided for @powerSaver.
  ///
  /// In en, this message translates to:
  /// **'Low power'**
  String get powerSaver;

  /// No description provided for @powerBalanced.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get powerBalanced;

  /// No description provided for @powerPerformance.
  ///
  /// In en, this message translates to:
  /// **'High performance'**
  String get powerPerformance;

  /// No description provided for @powerNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'Power modes need power-profiles-daemon, which this system doesn\'t have.'**
  String get powerNoProfiles;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @batteryUntilFull.
  ///
  /// In en, this message translates to:
  /// **'{time} until full'**
  String batteryUntilFull(String time);

  /// No description provided for @batteryLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String batteryLeft(String time);

  /// No description provided for @batteryHealth.
  ///
  /// In en, this message translates to:
  /// **'Battery health'**
  String get batteryHealth;

  /// No description provided for @batteryHealthHelp.
  ///
  /// In en, this message translates to:
  /// **'How much the battery holds compared to when it was new.'**
  String get batteryHealthHelp;

  /// No description provided for @batteryLowPowerHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses less power so the battery lasts longer.'**
  String get batteryLowPowerHelp;

  /// No description provided for @mouseNaturalScrollingHelp.
  ///
  /// In en, this message translates to:
  /// **'Content follows the movement of your fingers.'**
  String get mouseNaturalScrollingHelp;

  /// No description provided for @printersDefaultFailed.
  ///
  /// In en, this message translates to:
  /// **'The default printer couldn\'t be changed.'**
  String get printersDefaultFailed;

  /// No description provided for @usersStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get usersStandard;

  /// No description provided for @keyboardSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get keyboardSystemDefault;

  /// No description provided for @keyboardSourceFirst.
  ///
  /// In en, this message translates to:
  /// **'Active at start'**
  String get keyboardSourceFirst;

  /// No description provided for @keyboardSourceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get keyboardSourceRemove;

  /// No description provided for @keyboardSourcesHelp.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+Space to switch to the next source. You can add up to four.'**
  String get keyboardSourcesHelp;

  /// No description provided for @keyboardSourcesFull.
  ///
  /// In en, this message translates to:
  /// **'Four sources is the most. Remove one to add another.'**
  String get keyboardSourcesFull;

  /// No description provided for @keyboardChooseLayout.
  ///
  /// In en, this message translates to:
  /// **'Choose a keyboard layout'**
  String get keyboardChooseLayout;

  /// No description provided for @keyboardChooseVariant.
  ///
  /// In en, this message translates to:
  /// **'Choose a variant'**
  String get keyboardChooseVariant;

  /// No description provided for @keyboardVariantDefault.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get keyboardVariantDefault;

  /// No description provided for @paneTrackpad.
  ///
  /// In en, this message translates to:
  /// **'Trackpad'**
  String get paneTrackpad;

  /// No description provided for @mouseLeftButton.
  ///
  /// In en, this message translates to:
  /// **'Left button'**
  String get mouseLeftButton;

  /// No description provided for @mouseSecondaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Which button opens context menus.'**
  String get mouseSecondaryHelp;

  /// No description provided for @trackpadTrackingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Tracking speed'**
  String get trackpadTrackingSpeed;

  /// No description provided for @trackpadTapToClick.
  ///
  /// In en, this message translates to:
  /// **'Tap to click'**
  String get trackpadTapToClick;

  /// No description provided for @trackpadTapToClickHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap with one finger to click.'**
  String get trackpadTapToClickHelp;

  /// No description provided for @trackpadSecondaryClick.
  ///
  /// In en, this message translates to:
  /// **'Secondary click'**
  String get trackpadSecondaryClick;

  /// No description provided for @trackpadTwoFingers.
  ///
  /// In en, this message translates to:
  /// **'Click or tap with two fingers'**
  String get trackpadTwoFingers;

  /// No description provided for @trackpadBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Click in the bottom right corner'**
  String get trackpadBottomRight;

  /// No description provided for @trackpadBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Click in the bottom left corner'**
  String get trackpadBottomLeft;

  /// No description provided for @trackpadDisableWhileTyping.
  ///
  /// In en, this message translates to:
  /// **'Ignore the trackpad while typing'**
  String get trackpadDisableWhileTyping;

  /// No description provided for @trackpadDisableWhileTypingHelp.
  ///
  /// In en, this message translates to:
  /// **'Stops a palm resting on the trackpad from moving the pointer.'**
  String get trackpadDisableWhileTypingHelp;

  /// No description provided for @appearanceAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Automatic turns dark at sunset and back to light at sunrise, for the time zone\'s place.'**
  String get appearanceAutoNote;

  /// No description provided for @soundAlertPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get soundAlertPlay;

  /// No description provided for @soundEffectsPending.
  ///
  /// In en, this message translates to:
  /// **'Playing effects through a chosen device and a startup sound aren’t available yet.'**
  String get soundEffectsPending;

  /// No description provided for @soundNoService.
  ///
  /// In en, this message translates to:
  /// **'The sound service isn’t running: these can’t be changed now.'**
  String get soundNoService;

  /// No description provided for @energyDisplayOff.
  ///
  /// In en, this message translates to:
  /// **'Turn the display off after'**
  String get energyDisplayOff;

  /// No description provided for @energySleep.
  ///
  /// In en, this message translates to:
  /// **'Put the computer to sleep after'**
  String get energySleep;

  /// No description provided for @energyInhibited.
  ///
  /// In en, this message translates to:
  /// **'The computer is being kept awake now.'**
  String get energyInhibited;

  /// No description provided for @focusModesHeading.
  ///
  /// In en, this message translates to:
  /// **'Focus modes'**
  String get focusModesHeading;

  /// No description provided for @focusAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Focus…'**
  String get focusAdd;

  /// No description provided for @focusNoModes.
  ///
  /// In en, this message translates to:
  /// **'No Focus modes yet. Add one to choose which apps and people can still reach you.'**
  String get focusNoModes;

  /// No description provided for @focusModesNote.
  ///
  /// In en, this message translates to:
  /// **'Every Focus silences banners and sounds like Do Not Disturb. Letting the allowed apps through needs the shell.'**
  String get focusModesNote;

  /// No description provided for @focusTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on {name}'**
  String focusTurnOn(String name);

  /// No description provided for @focusEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Focus'**
  String get focusEditTitle;

  /// No description provided for @focusNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Focus'**
  String get focusNewTitle;

  /// No description provided for @focusName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get focusName;

  /// No description provided for @focusSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get focusSymbol;

  /// No description provided for @focusAllowedApps.
  ///
  /// In en, this message translates to:
  /// **'Allowed apps'**
  String get focusAllowedApps;

  /// No description provided for @focusAllowedAppsHelp.
  ///
  /// In en, this message translates to:
  /// **'Notifications from these apps still come through.'**
  String get focusAllowedAppsHelp;

  /// No description provided for @focusNoApps.
  ///
  /// In en, this message translates to:
  /// **'No app has sent a notification yet.'**
  String get focusNoApps;

  /// No description provided for @focusAllowedPeople.
  ///
  /// In en, this message translates to:
  /// **'Allowed people'**
  String get focusAllowedPeople;

  /// No description provided for @focusAllowedPeopleHelp.
  ///
  /// In en, this message translates to:
  /// **'Messages from these people still come through.'**
  String get focusAllowedPeopleHelp;

  /// No description provided for @focusPersonPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a name'**
  String get focusPersonPlaceholder;

  /// No description provided for @focusRemovePerson.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String focusRemovePerson(String name);

  /// No description provided for @focusDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Focus'**
  String get focusDelete;

  /// No description provided for @focusTooMany.
  ///
  /// In en, this message translates to:
  /// **'32 Focus modes is the most. Delete one to add another.'**
  String get focusTooMany;

  /// No description provided for @focusSummary.
  ///
  /// In en, this message translates to:
  /// **'{apps, plural, =0{No apps} =1{1 app} other{{apps} apps}}, {people, plural, =0{no people} =1{1 person} other{{people} people}}'**
  String focusSummary(int apps, int people);

  /// No description provided for @displaysOnlyActive.
  ///
  /// In en, this message translates to:
  /// **'Only the display in use can be changed for now.'**
  String get displaysOnlyActive;

  /// No description provided for @displaysChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'The display wasn’t changed: {reason}'**
  String displaysChangeFailed(String reason);

  /// No description provided for @displaysKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these display settings?'**
  String get displaysKeepTitle;

  /// No description provided for @displaysKeepBody.
  ///
  /// In en, this message translates to:
  /// **'The display goes back to how it was in {seconds, plural, =1{1 second} other{{seconds} seconds}}.'**
  String displaysKeepBody(int seconds);

  /// No description provided for @displaysKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get displaysKeep;

  /// No description provided for @displaysRevert.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get displaysRevert;

  /// No description provided for @displaysHz.
  ///
  /// In en, this message translates to:
  /// **'{rate} Hz'**
  String displaysHz(String rate);

  /// No description provided for @displaysScaleValue.
  ///
  /// In en, this message translates to:
  /// **'{scale}×'**
  String displaysScaleValue(String scale);

  /// No description provided for @displaysRotate90.
  ///
  /// In en, this message translates to:
  /// **'90°'**
  String get displaysRotate90;

  /// No description provided for @displaysRotate180.
  ///
  /// In en, this message translates to:
  /// **'180°'**
  String get displaysRotate180;

  /// No description provided for @displaysRotate270.
  ///
  /// In en, this message translates to:
  /// **'270°'**
  String get displaysRotate270;

  /// No description provided for @displaysNightSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get displaysNightSchedule;

  /// No description provided for @displaysNightAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get displaysNightAllDay;

  /// No description provided for @displaysNightSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset to sunrise'**
  String get displaysNightSunset;

  /// No description provided for @displaysNightCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get displaysNightCustom;

  /// No description provided for @displaysNightFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get displaysNightFrom;

  /// No description provided for @displaysNightTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get displaysNightTo;

  /// No description provided for @displaysNightTemperature.
  ///
  /// In en, this message translates to:
  /// **'Colour temperature'**
  String get displaysNightTemperature;

  /// No description provided for @displaysNightLess.
  ///
  /// In en, this message translates to:
  /// **'Less warm'**
  String get displaysNightLess;

  /// No description provided for @displaysNightMore.
  ///
  /// In en, this message translates to:
  /// **'More warm'**
  String get displaysNightMore;

  /// No description provided for @displaysNightActive.
  ///
  /// In en, this message translates to:
  /// **'The displays are warm now.'**
  String get displaysNightActive;

  /// No description provided for @displaysNightOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get displaysNightOff;

  /// No description provided for @displaysNightOnAllDay.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get displaysNightOnAllDay;

  /// No description provided for @displaysNightOnCustom.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String displaysNightOnCustom(String from, String to);

  /// No description provided for @displaysNightBadTime.
  ///
  /// In en, this message translates to:
  /// **'Use the 24-hour form, such as 21:30.'**
  String get displaysNightBadTime;

  /// No description provided for @displaysNightFailed.
  ///
  /// In en, this message translates to:
  /// **'Night light wasn’t changed: {reason}'**
  String displaysNightFailed(String reason);

  /// No description provided for @displaysNoCompositor.
  ///
  /// In en, this message translates to:
  /// **'The compositor didn’t report its displays, so they can’t be changed from here. This is what the machine lists.'**
  String get displaysNoCompositor;

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @menuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// No description provided for @menuWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// No description provided for @menuBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get menuBack;

  /// No description provided for @menuForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get menuForward;

  /// No description provided for @menuSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get menuSearch;

  /// No description provided for @menuWritingTools.
  ///
  /// In en, this message translates to:
  /// **'Writing Tools'**
  String get menuWritingTools;

  /// No description provided for @menuAutoFill.
  ///
  /// In en, this message translates to:
  /// **'AutoFill'**
  String get menuAutoFill;

  /// No description provided for @menuStartDictation.
  ///
  /// In en, this message translates to:
  /// **'Start Dictation…'**
  String get menuStartDictation;

  /// No description provided for @menuEmojiSymbols.
  ///
  /// In en, this message translates to:
  /// **'Emoji & Symbols'**
  String get menuEmojiSymbols;

  /// No description provided for @shortcutsHelp.
  ///
  /// In en, this message translates to:
  /// **'Click the keys of a shortcut to record new ones; Escape cancels. Logo is the key with the system logo.'**
  String get shortcutsHelp;

  /// No description provided for @shortcutsRestoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get shortcutsRestoreDefaults;

  /// No description provided for @shortcutRecording.
  ///
  /// In en, this message translates to:
  /// **'Press the keys…'**
  String get shortcutRecording;

  /// No description provided for @shortcutNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get shortcutNone;

  /// No description provided for @shortcutNeedsModifier.
  ///
  /// In en, this message translates to:
  /// **'Hold Logo, Control or Alt with the key.'**
  String get shortcutNeedsModifier;

  /// No description provided for @shortcutInUse.
  ///
  /// In en, this message translates to:
  /// **'Already used by “{action}”.'**
  String shortcutInUse(String action);

  /// No description provided for @shortcutsInputSources.
  ///
  /// In en, this message translates to:
  /// **'Input sources'**
  String get shortcutsInputSources;

  /// No description provided for @shortcutScreenClipboard.
  ///
  /// In en, this message translates to:
  /// **'Picture of the whole screen, to the clipboard'**
  String get shortcutScreenClipboard;

  /// No description provided for @shortcutSelectionClipboard.
  ///
  /// In en, this message translates to:
  /// **'Picture of a selected area, to the clipboard'**
  String get shortcutSelectionClipboard;

  /// No description provided for @shortcutLauncher.
  ///
  /// In en, this message translates to:
  /// **'Show the launcher'**
  String get shortcutLauncher;

  /// No description provided for @shortcutNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show Notification Center'**
  String get shortcutNotifications;

  /// No description provided for @shortcutControlCenter.
  ///
  /// In en, this message translates to:
  /// **'Show Control Center'**
  String get shortcutControlCenter;

  /// No description provided for @shortcutHideApp.
  ///
  /// In en, this message translates to:
  /// **'Hide the app'**
  String get shortcutHideApp;

  /// No description provided for @shortcutHideOthers.
  ///
  /// In en, this message translates to:
  /// **'Hide the other apps'**
  String get shortcutHideOthers;

  /// No description provided for @shortcutFill.
  ///
  /// In en, this message translates to:
  /// **'Fill the screen'**
  String get shortcutFill;

  /// No description provided for @shortcutLeftHalf.
  ///
  /// In en, this message translates to:
  /// **'Left half of the screen'**
  String get shortcutLeftHalf;

  /// No description provided for @shortcutRightHalf.
  ///
  /// In en, this message translates to:
  /// **'Right half of the screen'**
  String get shortcutRightHalf;

  /// No description provided for @shortcutTopHalf.
  ///
  /// In en, this message translates to:
  /// **'Top half of the screen'**
  String get shortcutTopHalf;

  /// No description provided for @shortcutBottomHalf.
  ///
  /// In en, this message translates to:
  /// **'Bottom half of the screen'**
  String get shortcutBottomHalf;

  /// No description provided for @shortcutNextSource.
  ///
  /// In en, this message translates to:
  /// **'Next input source'**
  String get shortcutNextSource;

  /// No description provided for @menuBarHideAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get menuBarHideAlways;

  /// No description provided for @accessibilityIncreaseContrastHelp.
  ///
  /// In en, this message translates to:
  /// **'Stronger text, borders and separators, and a deeper accent, in every app.'**
  String get accessibilityIncreaseContrastHelp;

  /// No description provided for @accessibilityPointerSize.
  ///
  /// In en, this message translates to:
  /// **'Pointer size'**
  String get accessibilityPointerSize;

  /// No description provided for @accessibilityPointerSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'The size of the pointer on the screen.'**
  String get accessibilityPointerSizeHelp;

  /// No description provided for @accessibilityPointerNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get accessibilityPointerNormal;

  /// No description provided for @accessibilityPointerLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get accessibilityPointerLarge;

  /// No description provided for @accessibilityTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get accessibilityTextSize;

  /// No description provided for @accessibilityTextDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accessibilityTextDefault;

  /// No description provided for @accessibilityTextLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get accessibilityTextLarger;

  /// No description provided for @accessibilityLargerTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Makes the text of the apps larger. The menu bar, the Dock and the other parts of the desktop keep their size.'**
  String get accessibilityLargerTextHelp;

  /// No description provided for @screenSaver.
  ///
  /// In en, this message translates to:
  /// **'Screen saver'**
  String get screenSaver;

  /// No description provided for @screenSaverStartAfter.
  ///
  /// In en, this message translates to:
  /// **'Start after'**
  String get screenSaverStartAfter;

  /// No description provided for @screenSaverDrift.
  ///
  /// In en, this message translates to:
  /// **'Drift'**
  String get screenSaverDrift;

  /// No description provided for @screenSaverClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get screenSaverClock;

  /// No description provided for @screenSaverColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get screenSaverColors;

  /// No description provided for @screenSaverHelp.
  ///
  /// In en, this message translates to:
  /// **'The screen saver starts when the computer has been idle for this long and ends with any key or movement. The lock screen asks for the password after the delay set in Lock Screen.'**
  String get screenSaverHelp;

  /// No description provided for @lockPasswordDelayHelp.
  ///
  /// In en, this message translates to:
  /// **'The password is asked for after the screen saver starts or the display turns off, and before the computer sleeps.'**
  String get lockPasswordDelayHelp;

  /// No description provided for @replacementsShortcut.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replacementsShortcut;

  /// No description provided for @replacementsPhrase.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get replacementsPhrase;

  /// No description provided for @replacementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No text replacements yet.'**
  String get replacementsEmpty;

  /// No description provided for @replacementsHelp.
  ///
  /// In en, this message translates to:
  /// **'Typing a shortcut and then a space or punctuation replaces it with the text, in every app.'**
  String get replacementsHelp;

  /// No description provided for @replacementsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Needs both texts.'**
  String get replacementsIncomplete;

  /// No description provided for @replacementsNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'No spaces in the shortcut.'**
  String get replacementsNoSpaces;

  /// No description provided for @replacementsRepeated.
  ///
  /// In en, this message translates to:
  /// **'Already used.'**
  String get replacementsRepeated;

  /// No description provided for @replacementsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get replacementsAdd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
