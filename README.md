# Beoplay Remote for macOS

This is an unofficial menu bar app for macOS to remote control network enabled Beoplay loudspeakers.

## Example

![Screenshot](./screenshot.png)

The menu bar has basic support for play/pause and forward/backward. The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original Bang&Olufsen iOS app, Spotify, etc. Speakers are automatically discovered via Bonjour.


## Hotkeys / keyboard shortcuts
Apple keyboards features <kbd>volume-down</kbd> and <kbd>volume-up</kbd> keys to control the volume of the local speakers. When the same physical keys function as <kbd>F11</kbd> and <kbd>F12</kbd> keys they control the volume of the remote speakers via this application.

| Local speakers           | Remote speakers                        |
| ------------------------ | -------------------------------------- |
| <kbd>volume-down</kbd>   | <kbd>fn</kbd> + <kbd>volume-down</kbd> |
| <kbd>volume-up</kbd>     | <kbd>fn</kbd> + <kbd>volume-up</kbd>   |


## Command line
This application is built with the [RemoteCore library](https://github.com/tlk/beoplay-macos-remote-cli) which features a command line interface.


# Installation
```
$ xcodebuild -version
Xcode 11.0
Build version 11M336w

$ make install
xcodebuild [..]
rm -rf /Applications/BeoplayRemoteGUI.app
cp -rp Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app /Applications
$
```

## Enable hotkeys
```
$ bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
$ defaults write $bundleid hotkeys.enabled true
```
The application will ask for permission to 'control this computer using accessibility features'. Hotkeys will not work without this permission.

Finally, disconnect <kbd>F11</kbd> and <kbd>F12</kbd> from Mission Control: https://apple.stackexchange.com/a/110528


## Optional configuration
```
$ bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
$ defaults write $bundleid hotkeys.enabled true
$ defaults write $bundleid hotkeys.volumedownKey 103
$ defaults write $bundleid hotkeys.volumeupKey 111
$ defaults write $bundleid hotkeys.step 4
```
