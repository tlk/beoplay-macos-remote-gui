# Configuration

The application can be configured via the command line (Terminal.app). The app will only pick up configuration changes when it is opened.

Example:
```
defaults write -app BeoplayRemoteGUI app.title "B&O"

defaults write -app BeoplayRemoteGUI hotkeys.PrevDevice  disabled
defaults write -app BeoplayRemoteGUI hotkeys.NextDevice  disabled
defaults write -app BeoplayRemoteGUI hotkeys.Leave       disabled
defaults write -app BeoplayRemoteGUI hotkeys.Join        disabled
defaults write -app BeoplayRemoteGUI hotkeys.PrevSource  disabled
defaults write -app BeoplayRemoteGUI hotkeys.NextSource  disabled
```

See current configuration:
```
defaults read -app BeoplayRemoteGUI
```

Reset all configuration to start over:
```
defaults delete -app BeoplayRemoteGUI
```


## App display name in the menu

Customize the app name in the menu bar:
```
defaults write -app BeoplayRemoteGUI app.title "B&O"
```


## Hotkeys (keyboard shortcuts)

Default configuration:

| Action           | Key            |
| ---------------- | -------------- |
| PrevDevice       | <kbd>F1 </kbd> |
| NextDevice       | <kbd>F2 </kbd> |
| Leave            | <kbd>F3 </kbd> |
| Join             | <kbd>F4 </kbd> |
| PrevSource       | <kbd>F5 </kbd> |
| NextSource       | <kbd>F6 </kbd> |
| Back             | <kbd>F7 </kbd> |
| TogglePlayPause  | <kbd>F8 </kbd> |
| Next             | <kbd>F9 </kbd> |
| ToggleMute       | <kbd>F10</kbd> |
| VolumeDown       | <kbd>F11</kbd> |
| VolumeUp         | <kbd>F12</kbd> |


Manual configuration:
```
defaults write -app BeoplayRemoteGUI hotkeys.enabled true
defaults write -app BeoplayRemoteGUI hotkeys.VolumeStep 4

defaults write -app BeoplayRemoteGUI hotkeys.PrevDevice       disabled
defaults write -app BeoplayRemoteGUI hotkeys.NextDevice       disabled
defaults write -app BeoplayRemoteGUI hotkeys.Leave            disabled
defaults write -app BeoplayRemoteGUI hotkeys.Join             disabled
defaults write -app BeoplayRemoteGUI hotkeys.PrevSource       disabled
defaults write -app BeoplayRemoteGUI hotkeys.NextSource       disabled
defaults write -app BeoplayRemoteGUI hotkeys.Back             f7
defaults write -app BeoplayRemoteGUI hotkeys.TogglePlayPause  f8
defaults write -app BeoplayRemoteGUI hotkeys.Next             f9
defaults write -app BeoplayRemoteGUI hotkeys.ToggleMute      f10
defaults write -app BeoplayRemoteGUI hotkeys.VolumeDown      f11
defaults write -app BeoplayRemoteGUI hotkeys.VolumeUp        f12
```

Note that some hotkeys such as <kbd>F11</kbd> and <kbd>F12</kbd> may already be in use by other applications.
Consider changing the configuration of those applications or disabling the hotkeys for this application as illustrated above. See [Mission Control](https://apple.stackexchange.com/a/110528) (<kbd>F11</kbd>) and [Google Chrome](https://chrome.google.com/webstore/detail/disable-f12/kpfnljnhmfhomajodmlepkcoflmbjiaf) (<kbd>F12</kbd>).


## Customize names for B&O Radio stations

Favorite radio stations are automatically fetched from the selected B&O device. This is fine in most cases.

Optionally, the display name of a radio station can be set manually by adding an entry to beoradio.stations with a custom station name.

```
defaults write -app BeoplayRemoteGUI beoradio.enabled true
defaults write -app BeoplayRemoteGUI beoradio.stations  -dict-add 8389481460675598 "DR P4"
defaults write -app BeoplayRemoteGUI beoradio.stations  -dict-add 5207345892675221 "DR P6"
defaults write -app BeoplayRemoteGUI beoradio.stations  -dict-add 4338732615578920 "DR P8"
```

