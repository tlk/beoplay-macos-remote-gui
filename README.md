# Beoplay Remote for macOS

This is an unofficial app to remote control network enabled [Bang & Olufsen](https://www.bang-olufsen.com/) loudspeakers from macOS.

![Screenshot](./screenshot.jpg)

The menu bar app has basic support for play/pause and forward/backward. The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original Bang&Olufsen iOS app, Spotify and Deezer. Speakers are automatically discovered via Bonjour.



Apple keyboards features <kbd>volume-down</kbd> and <kbd>volume-up</kbd> keys to control the volume of the local speakers. When the same physical keys function as <kbd>F11</kbd> and <kbd>F12</kbd> keys they can control the volume of the remote speakers via this application.

| Local speakers           | Remote speakers                        |
| ------------------------ | -------------------------------------- |
| <kbd>volume-down</kbd>   | <kbd>fn</kbd> + <kbd>volume-down</kbd> |
| <kbd>volume-up</kbd>     | <kbd>fn</kbd> + <kbd>volume-up</kbd>   |



## Installation

The latest version of BeoplayRemoteGUI.app — code-signed with a registered Apple ID from the developer — is available for download at the Github project release page:

* https://github.com/tlk/beoplay-macos-remote-gui/releases
* https://www.beoplayremote.com (which simply links to the above)


## Configuration

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

Please see [Configuration.md](Configuration.md) for additional configuration.


## Build from source
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

## Read more
* See the [beoplay-cli](https://github.com/tlk/beoplay-macos-remote-cli) for a command line interface
* [How do I control the volume in spotify with the volume buttons on my apple keyboard?](https://community.spotify.com/t5/Desktop-Mac/How-do-I-control-the-volume-in-spotify-with-the-volume-buttons/m-p/4726068) (Spotify Community)
* [Beoplay Remote for macOS (PoC)](https://forum.beoworld.org/forums/t/37724.aspx) (BeoWorld)

