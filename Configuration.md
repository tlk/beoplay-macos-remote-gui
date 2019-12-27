# Optional configuration

### Default device name (auto-connect)
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid devices.default "Beoplay M5 i køkkenet"
```

### Custom app name in the menu bar
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid app.title "B&O"
```

### Reset all configuration
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults delete $bundleid
```


## Hotkeys
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid hotkeys.enabled true
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
defaults write $bundleid hotkeys.VolumeStep 4
```

## TuneIn radio stations

The tuneIn menu item is enabled via the tuneIn.enabled setting. Favorites are fetched from the local B&O device which in turn uses a tuneIn account to fetch favorite radio stations from https://tunein.com

The name of a radio station can be customized by adding an entry to tuneIn.stations with a custom station name. Make sure that the station id matches:


```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid tuneIn.enabled true
defaults write $bundleid tuneIn.stations -dict-add s37309 "DR P4"
```

### Without a TuneIn account

Favorite radio stations can be configured without a TuneIn account via tuneIn.stations and tuneIn.order:


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

