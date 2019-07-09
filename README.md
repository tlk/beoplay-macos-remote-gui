# Beoplay Remote for macOS

This is an unofficial menu bar app for macOS to remote control network enabled Beoplay loudspeakers.

## Example

![Screenshot](./screenshot.png)

The menu bar has basic support for play/pause and forward/backward. The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original Bang&Olufsen iOS app, Spotify, etc. Speakers are automatically discovered via Bonjour.


## Hotkeys / keyboard shortcuts
Apple keyboards features <button>volume-down</button> and <button>volume-up</button> keys to control the volume of the local device. When the same physical keys function as <button>F11</button> and <button>F12</button> keys they control the volume of the remote speakers.

| Local device                 | Remote speakers                                    |
| ---------------------------- | -------------------------------------------------- |
| <button>volume-down</button> | <button>fn</button> + <button>volume-down</button> |
| <button>volume-up</button>   | <button>fn</button> + <button>volume-up</button>   |


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

## Optional configuration
```
$ bundleid=$(defaults read /Applications/BeoplayRemoteGUI.app/Contents/Info.plist CFBundleIdentifier)
$ defaults write $bundleid hotkeys.enabled true
$ defaults write $bundleid hotkeys.volumedownKey 103
$ defaults write $bundleid hotkeys.volumeupKey 111
$ defaults write $bundleid hotkeys.step 4
```
