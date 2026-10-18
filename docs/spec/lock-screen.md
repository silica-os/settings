# Lock screen pane

Inventory item ST-LCK-01, capture SH-LK-01. Light captured. The lock screen and the login
window themselves were not shown (*unmeasured*).

| Control | Kind | Value read |
| --- | --- | --- |
| Turn the display off when inactive | pop-up | after 30 minutes |
| Require the password after sleep or screen saver | pop-up | after 15 minutes |
| Show user name and photo | switch | on |
| Show password hints | switch | off |
| Show a message when locked | switch with a set button | off |
| Login window shows (also when switching users) | radio group: list of users / name and password fields | *unmeasured* |
| Show sleep, restart and shut down buttons | switch | on |
| Accessibility options | button | — |

## In Silica

The lock screen is the shell's `lock` layer; its look is ours (the reference one was not
captured). Working controls: the display-off time (`power.json`), the password delay and the
user's name and picture (`lockscreen.json`). The hints, the lock message, the login window
options and the power buttons stay disabled (silica-os/settings#50).
