# Configuration files Settings writes for the shell

Settings and the shell talk through small JSON objects in `$XDG_CONFIG_HOME/silica`
(usually `~/.config/silica`). This page is the contract: the shell reads exactly these keys,
Settings writes exactly these keys. Code: `lib/src/system/config.dart` (the store) and
`lib/src/system/shell_config.dart` (the keys not wired yet). Tests: `test/shell_config_test.dart`.

## Rules for both sides

- Every file is one JSON object. Settings changes **one key at a time and keeps the others**,
  so a reader must ignore keys it does not know.
- A missing file, a missing key, a value of the wrong type or outside its set means **the
  default**. A reader never fails on a bad value.
- A file is written to `<name>.json.tmp` in the same folder and then renamed over
  `<name>.json`, so a reader never sees half a file. A watcher must watch the **folder** and
  filter on the file name (the rename replaces the inode); changes are bursty, so debounce.
- Types: `bool` is JSON `true` / `false`; sizes are JSON **integers** (points); enumerations
  are lower-camel-case strings.
- Status: **written** means Settings writes it today, with a working control; **not wired**
  means the schema is fixed and implemented (`ShellConfigWrites`), but the control stays
  disabled and nothing is written until the shell reads the key (AGENTS.md, never fake).
  When the shell implements a key, the Settings change is to enable the control and call the
  writer.

## dock.json

| Key | Type / values | Default | Status |
| --- | --- | --- | --- |
| `position` | `"left"` \| `"bottom"` \| `"right"` | `"bottom"` | written (only `bottom` can be chosen) |
| `minimizeEffect` | `"genie"` \| `"scale"` | `"genie"` | written |
| `magnify` | bool | `true` | written |
| `autohide` | bool | `false` | written |
| `indicators` | bool | `true` | written |
| `recents` | bool | `false` | written |
| `tileSize` | integer, 16..128 (pt of the icon at rest) | `48` | written |
| `magnifiedSize` | integer, `tileSize`..`floor(tileSize * 132 / 63)` (pt of the icon under the pointer) | `52` | written |
| `launchAnimation` | `"bounce"` \| `"none"` | `"bounce"` | written (the shell reads it live) |
| `titleBarDoubleClick` | `"zoom"` \| `"minimize"` \| `"none"` | `"zoom"` | written (Ossido's title bars and silica_ui apps) |
| `minimizeToApp` | bool (windows minimize into their app's icon) | `false` | written (the shell hides the separate cells and tells Ossido where the icons are) |

Settings writes `tileSize` first and clamps `magnifiedSize` to the tile it just wrote; a
reader must still clamp (`magnifiedSize` below `tileSize` means no magnification). The sliders
map linearly onto the integer range. `magnify: false` ignores `magnifiedSize`.

## menubar.json

| Key | Type / values | Default | Status |
| --- | --- | --- | --- |
| `sound` | `"always"` \| `"active"` \| `"never"` | `"active"` | written |
| `bluetooth` | bool | `false` | written |
| `battery` | bool | `true` | written |
| `batteryPercent` | bool (only meaningful with `battery`) | `false` | written |
| `autohide` | `"never"` \| `"fullscreen"` \| `"always"` | `"fullscreen"` | written (the shell reads it live; the bar comes back at the top edge) |
| `background` | bool (the bar's translucent background) | `false` (the reference bar is bare) | written (the shell reads it live) |
| `recentItems` | integer, one of 0, 5, 10, 15, 20, 30, 50 (how many recent apps and documents the logo menu lists) | `10` | written |
| `clock` | object, below | see below | written (the shell reads it live) |

`clock` is written as a whole object (all keys but `hour24` always present):

| Key | Type / values | Default |
| --- | --- | --- |
| `hour24` | bool; **absent** means 24 hours (the shell does not read the language's 12/24 preference yet) | absent |
| `seconds` | bool | `false` |
| `weekday` | bool | `true` |
| `date` | `"auto"` (when there is room: today as `always`) \| `"always"` \| `"never"` (the weekday alone stays when `weekday` is on) | `"auto"` |

A value of `recentItems` off the list is read as `10`. A `clock` that is not an object, or a
key of it with the wrong type, takes that key's default.

## notifications.json

```json
{
  "previews": "always",
  "grouping": "automatic",
  "apps": {
    "<desktop entry id or app name>": {
      "style": "banners",
      "badges": true,
      "sound": true,
      "previews": "always",
      "grouping": "auto",
      "showInCenter": true
    }
  }
}
```

| Key | Type / values | Default | Status |
| --- | --- | --- | --- |
| `apps.<id>.style` | `"banners"` \| `"alerts"` \| `"none"` | `"banners"` | written (the shell reads it) |
| `apps.<id>.badges` | bool | `true` | not wired |
| `apps.<id>.sound` | bool | `true` | written (the shell plays the chosen alert sound with a banner; `false` mutes the app) |
| `apps.<id>.previews` | `"always"` \| `"unlocked"` \| `"never"` | the global `previews` | written (the shell reads it; `unlocked` shows the text: there is no lock screen) |
| `apps.<id>.grouping` | `"auto"` \| `"app"` \| `"off"` (the shell also takes `automatic` and `byApp`) | the global `grouping` | written (`off` lists each notification of the app in the Center; the others fold them into a stack) |
| `apps.<id>.showInCenter` | bool | `true` | written (`false` keeps the app out of the Center) |
| `previews` (global) | `"always"` \| `"unlocked"` \| `"never"` | `"always"` | written |
| `grouping` (global) | `"automatic"` \| `"byApp"` \| `"off"` | `"automatic"` | not wired |

The per-app keys are optional: Settings removes a per-app key (instead of writing a "default"
value) when the app should follow the global one. `<id>` is the notification's group (desktop
entry) or its app name, as the shell matches today. `style: "none"` is "notifications off for
this app". Do Not Disturb is not in this file: it goes through the daemon.

## wallpaper.json

Exactly one of:

```json
{ "color": "#7a7b80" }
{ "image": "/absolute/path/to/picture.png" }
```

plus the optional `fit`: `"fill"` \| `"fit"` \| `"stretch"` \| `"center"` \|
`"tile"`, default `"fill"`. Choosing a new color or picture **replaces** the object (never
both `color` and `image`) and keeps `fit`. The color is `#rrggbb`. Settings writes it on the
spot; the shell watches the file (folder watch, as above) and repaints without a new login. The
fit does not apply to a color. A missing or unreadable image falls back to the default color.

## Files Ossido and silica-daemon read

These are read by the compositor and the daemon (silica-desktop `docs/control.md` and
`docs/daemon.md` are the contract); Settings writes them through `lib/src/system/settings_files.dart`
and their controls are **written**. Ranges are the readers'; Settings stays inside them.

### shortcuts.json

```json
{ "window.minimize": "Logo+N", "faro.toggle": null }
```

The keyboard shortcuts sheet (`lib/src/system/shortcuts.dart`): per command id of the catalog,
the keys (`Logo+Shift+Q`: modifiers `Logo`, `Ctrl`, `Alt`, `Shift` and the xkb name of the key)
or `null` for none; a command left out has the catalog's default. While a new combination is
recorded Settings writes `"capture": true` so Ossido lets the keys reach it; removed at the end.
Settings refuses a combination already used by another shortcut of the sheet.

### keyboard.json

```json
{ "repeatDelay": 600, "repeatRate": 25, "layouts": ["us", "de(nodeadkeys)"] }
```

`repeatDelay` is an integer of 100–3000 ms and `repeatRate` an integer of 0–100 per second
(0 turns repeat off); the sliders offer the steps in `lib/src/panes/input.dart`. `layouts` is
the list of input sources, at most four, an xkb layout with an optional variant in parentheses;
none saved removes the key (xkb's default). `model` and `options` belong to the same file and
are kept untouched.

### input.json

```json
{
  "mouse": { "speed": 0.0, "naturalScroll": false, "secondaryClick": "right", "scrollSpeed": 1.0 },
  "touchpad": { "speed": 0.0, "naturalScroll": false, "tapToClick": false,
                "secondaryClick": "twoFinger", "disableWhileTyping": true, "scrollSpeed": 1.0 }
}
```

One object per device; a key is written only once the person changes it (a missing key gives
libinput's default for the device). `speed` is -1–1; `scrollSpeed` 0.1–10, shown on a
logarithmic slider with 1 in the middle; `mouse.secondaryClick` is `right` \| `left`;
`touchpad.secondaryClick` is `twoFinger` \| `bottomRight` \| `bottomLeft`. Settings keeps the
other device's object and `doubleClickMs`, which no control writes yet. The Trackpad pane is in
the sidebar only while silica-daemon's `State()` has `input.touchpad`.

### hotcorners.json

```json
{ "topLeft": "panorama", "bottomRight": "desktop" }
```

Read by Ossido (`docs/control.md`). One key per corner (`topLeft`, `topRight`, `bottomLeft`,
`bottomRight`); the action is `panorama`, `appWindows`, `desktop`, `notifications`, `launcher`,
`controlCenter` or `search`; "none" removes the key. The reference's quick note, screen saver,
display sleep, lock screen and the modifier variants are not offered (no such command yet).

### sound.json

```json
{ "uiSounds": true, "alert": "alert-crystal", "alertVolume": 1, "volumeFeedback": false }
```

Read by silica-daemon's sound service. `alert` is one of the `alert-*` names that
`Sound1.AlertSounds()` lists; `alertVolume` is 0–1 relative to the output volume;
`volumeFeedback` is a boolean (off by default). `uiSounds` is written by the daemon
(`SetUiSoundsEnabled`), not by Settings directly. The controls are enabled only while the sound
service answers; Settings plays the preview with `PlayAlert`.

### power.json

```json
{ "displayOffMinutes": 10, "sleepMinutes": 30, "preventSleep": false }
```

Read by Ossido (idle time, display off, asking the daemon to suspend) and by silica-daemon
(`preventSleep`: a logind `idle` inhibitor, read again every 30 s). Minutes are numbers above
zero; 0 or a missing key means never. Settings offers 1, 2, 5, 10, 15, 30 minutes and 1, 2,
3 hours, and shows any other saved value as it is. The Energy and Battery panes write all
three; the Lock Screen pane writes `displayOffMinutes`.

### focus.json

```json
{
  "active": "work",
  "modes": [
    { "id": "work", "name": "Work", "symbol": "person",
      "allowedApps": ["firefox"], "allowedPeople": ["Ada"] }
  ]
}
```

At most 32 modes; `id` is unique and never `dnd` (Do Not Disturb keeps it); Settings makes it
from the name (`work`, `work-2`…). `allowedApps` holds the keys of notifications.json `apps`.
Settings writes `modes` only; silica-daemon writes `active` (`System1.SetFocus`) and reports
the active mode in its state. Letting the allowed apps through is the shell's to do.

## theme.json (Appearance)

Settings' own persistence of the look; nobody else needs to read it. Settings applies it in its
window at once and tells silica-daemon (`System1.SetLook`), which keeps it for the session and
reads this file at its start. Apps and the shell read it **typed from the daemon's state**
(`look.*`, silica_ui `SilicaSystemLook`), not from the file; the Settings portal publishes
`accent-color`. Ossido watches the file for `glass`, `reduceTransparency` and `reduceMotion`.

| Key | Values | Default | Applied by |
| --- | --- | --- | --- |
| `accent` | `multicolour`, `blue`, `purple`, `pink`, `red`, `orange`, `yellow`, `green`, `graphite` | `multicolour` | silica_ui controls, portal `accent-color` |
| `highlight` | `automatic` or an accent name | `automatic` | silica_ui selected text |
| `sidebarIconSize` | `small`, `medium`, `large` | `medium` | silica_ui sidebars |
| `scrollBars` | `automatic`, `whenScrolling`, `always` | `automatic` | silica_ui scroll bars (`always`: legacy bar with its track) |
| `scrollClick` | `page`, `spot` | `page` | silica_ui scroll bar track click |
| `iconStyle` | `default`, `dark`, `clear`, `tinted` | `default` | silica_ui `SilicaIcon` without a style of its own (the Dock) |
| `glass` | number 0 (clearer) to 1 (more tinted) | `0.5` | Ossido (tint strength of the glass) |
| `keyboardNavigation` | bool | `false` | silica_ui: Tab reaches every Amalfi control (off: text fields and lists only) |
| `doubleClickMs` | integer 150–1000 | `300` | silica_ui: the longest time between the two clicks of a double click |
| `reduceTransparency` | bool | `false` | Ossido (opaque glass) and silica_ui (opaque Flutter glass) |
| `reduceMotion` | bool | `false` | Ossido (its own animations are skipped) and silica_ui (`MediaQuery.disableAnimations`) |

Not wired (controls disabled): `folderColour` (the daemon accepts it; the composed folder icons
do not take it yet) and `windowTint`.

## Other files (for completeness)

`lockscreen.json` and `settings.json` (`lastPane`, Settings'
own: the pane the window reopens on) are described in their panes' specs; the shell does not
need `settings.json`.
