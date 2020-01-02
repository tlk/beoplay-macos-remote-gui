# Optional configuration

Auto-connect to a default device:
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid devices.default "Beoplay M5 i køkkenet"
```

Customize the app name in the menu bar:
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid app.title "B&O"
```

Reset all configuration to start over:
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults delete $bundleid
```


## Hotkeys / keyboard shortcuts

Some hotkeys such as <kbd>F11</kbd> and <kbd>F12</kbd> might be assigned to functions in other applications.
This can be changed by changing the configuration of those other applications. See [Mission Control](https://apple.stackexchange.com/a/110528) (<kbd>F11</kbd>) and [Google Chrome](https://chrome.google.com/webstore/detail/disable-f12/kpfnljnhmfhomajodmlepkcoflmbjiaf) (<kbd>F12</kbd>).

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
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)

defaults write $bundleid hotkeys.enabled true
defaults write $bundleid hotkeys.VolumeStep 4

defaults write $bundleid hotkeys.PrevDevice       f1
defaults write $bundleid hotkeys.NextDevice       f2
defaults write $bundleid hotkeys.Leave            f3
defaults write $bundleid hotkeys.Join             f4
defaults write $bundleid hotkeys.PrevSource       f5
defaults write $bundleid hotkeys.NextSource       f6
defaults write $bundleid hotkeys.Back             f7
defaults write $bundleid hotkeys.TogglePlayPause  f8
defaults write $bundleid hotkeys.Next             f9
defaults write $bundleid hotkeys.ToggleMute      f10
defaults write $bundleid hotkeys.VolumeDown      f11
defaults write $bundleid hotkeys.VolumeUp        f12
```

## TuneIn radio stations

Favorite radio stations are fetched from the selected B&O device which in turn uses a tuneIn account to fetch favorite radio stations from https://tunein.com. The display name of a radio station can be customized by adding an entry to tuneIn.stations with a custom station name. Make sure that the station id matches.

```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid tuneIn.enabled true
defaults write $bundleid tuneIn.stations -dict-add s37309 "DR P4"
```

### Manual configuration with no TuneIn account

Favorite radio stations can be configured with tuneIn.stations and tuneIn.order. Double check that the entries in tuneIn.stations and tuneIn.order matches.

```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid tuneIn.enabled true
defaults write $bundleid tuneIn.stations -dict-add s24861 "DR P3"
defaults write $bundleid tuneIn.stations -dict-add s37309 "DR P4"
defaults write $bundleid tuneIn.stations -dict-add s69060 "DR P5"
defaults write $bundleid tuneIn.stations -dict-add s45455 "DR P6"
defaults write $bundleid tuneIn.stations -dict-add s69056 "DR P7"
defaults write $bundleid tuneIn.order -array s24861 s37309 s69060 s45455 s69056
```

