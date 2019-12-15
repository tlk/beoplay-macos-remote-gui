# Beoplay Remote for macOS

This is an unofficial menu bar app for macOS to remote control network enabled Beoplay loudspeakers.

![Screenshot](./screenshot.jpg)

The menu bar has basic support for play/pause and forward/backward. The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original Bang&Olufsen iOS app, Spotify, etc. Speakers are automatically discovered via Bonjour.



Apple keyboards features <kbd>volume-down</kbd> and <kbd>volume-up</kbd> keys to control the volume of the local speakers. When the same physical keys function as <kbd>F11</kbd> and <kbd>F12</kbd> keys they can control the volume of the remote speakers via this application.

| Local speakers           | Remote speakers                        |
| ------------------------ | -------------------------------------- |
| <kbd>volume-down</kbd>   | <kbd>fn</kbd> + <kbd>volume-down</kbd> |
| <kbd>volume-up</kbd>     | <kbd>fn</kbd> + <kbd>volume-up</kbd>   |



# Installation

## From source (recommended)
```
$ xcodebuild -version
Xcode 11.2.1
Build version 11B500

$ make install
xcodebuild [..]
rm -rf /Applications/BeoplayRemoteGUI.app
cp -rp Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app /Applications
$
```

## From github release

**Disclaimer: This procedure is not very user friendly! Proceed with caution!**

The latest release can be downloaded from the [Releases page](https://github.com/tlk/beoplay-macos-remote-gui/releases)

BeoplayRemoteGUI.app is [automatically compiled and relased](https://github.com/tlk/beoplay-macos-remote-gui/blob/master/.github/workflows/release.yml) by the github infrastructure. Downloading software from an unknown source is **not recommended** and Chrome as well as macOS do a great job warning you. Please read these instructions on how to [run an application that has not been signed with an Apple developer certificate](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unidentified-developer-mh40616/mac).


## Enable hotkeys
Please note that the following is done by copy-pasting into Terminal.app or similar.
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid hotkeys.enabled true
```
The application will ask for permission to 'control this computer using accessibility features'. Hotkeys will not work without this permission.

Some hotkeys (keyboard shortcuts) are used by other applications but fortunately there are ways to handle this. <kbd>F11</kbd> and <kbd>F12</kbd> in [Mission Control](https://apple.stackexchange.com/a/110528). <kbd>F12</kbd> in [Google Chrome](https://chrome.google.com/webstore/detail/disable-f12/kpfnljnhmfhomajodmlepkcoflmbjiaf).

| Key            | Action           |
| -------------- | ---------------- |
| <kbd>F1 </kbd> | PrevDevice       |
| <kbd>F2 </kbd> | NextDevice       |
| <kbd>F3 </kbd> | Leave            |
| <kbd>F4 </kbd> | Join             |
| <kbd>F5 </kbd> | PrevSource       |
| <kbd>F6 </kbd> | NextSource       |
| <kbd>F7 </kbd> | Back             |
| <kbd>F8 </kbd> | TogglePlayPause  |
| <kbd>F9 </kbd> | Next             |
| <kbd>F10</kbd> | ToggleMute       |
| <kbd>F11</kbd> | VolumeDown       |
| <kbd>F12</kbd> | VolumeUp         |


#### Optional hotkeys configuration
```
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid hotkeys.enabled true
defaults write $bundleid hotkeys.PrevDevice 122
defaults write $bundleid hotkeys.NextDevice 120
defaults write $bundleid hotkeys.Leave 99
defaults write $bundleid hotkeys.Join 118
defaults write $bundleid hotkeys.PrevSource 96
defaults write $bundleid hotkeys.NextSource 97
defaults write $bundleid hotkeys.Back 98
defaults write $bundleid hotkeys.TogglePlayPause 100
defaults write $bundleid hotkeys.Next 101
defaults write $bundleid hotkeys.ToggleMute 109
defaults write $bundleid hotkeys.VolumeDown 103
defaults write $bundleid hotkeys.VolumeUp 111
defaults write $bundleid hotkeys.VolumeStep 4
```



## Enable tuneIn
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

## Optional configuration
```
# Default device name (auto-connect):
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults write $bundleid devices.default "Beoplay M5 i køkkenet"

# Custom app name in the menu bar:
defaults write $bundleid app.title "BeoplayRemote"

# Reset all configuration:
bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
defaults delete $bundleid
```

## Known issues
Deezer and QPlay appear in the list of sources as "Music".
Selecting Deezer as a source will begin playback only when a playlist has already been added from the B&O app. Switching from Deezer to tuneIn and back to Deezer will not restart playback as the previous Deezer playlist has been cleared from the play queue. This is surprising as switching from Spotify to tuneIn and back works fine.

# Read more
* See the [beoplay-cli](https://github.com/tlk/beoplay-macos-remote-cli) for a command line interface
* [How do I control the volume in spotify with the volume buttons on my apple keyboard?](https://community.spotify.com/t5/Desktop-Mac/How-do-I-control-the-volume-in-spotify-with-the-volume-buttons/m-p/4726068) (Spotify Community)
* [Beoplay Remote for macOS (PoC)](https://forum.beoworld.org/forums/t/37724.aspx) (BeoWorld)
