# Beoplay Remote for macOS

This is an unofficial app to remote control network enabled [Bang & Olufsen](https://www.bang-olufsen.com/) loudspeakers from macOS.

![Screenshot](./screenshot.jpg)

The menu bar app has basic support for play/pause and forward/backward. The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original B&O iOS app, Spotify and Deezer. Speakers are automatically discovered via Bonjour. TuneIn favorite radio stations are fetched from the device and can be changed via [hotkeys](Configuration.md#hotkeys--keyboard-shortcuts).



Apple keyboards features <kbd>volume-down</kbd> and <kbd>volume-up</kbd> keys to control the volume of the local speakers. When the same physical keys function as <kbd>F11</kbd> and <kbd>F12</kbd> keys they can control the volume of the remote speakers via this application.

| Local speakers           | Remote speakers                        |
| ------------------------ | -------------------------------------- |
| <kbd>volume-down</kbd>   | <kbd>fn</kbd> + <kbd>volume-down</kbd> |
| <kbd>volume-up</kbd>     | <kbd>fn</kbd> + <kbd>volume-up</kbd>   |



## Download and installation

The latest version of BeoplayRemoteGUI.app — code-signed with a registered Apple ID from the developer — is available for download at the Github project release page:

* https://github.com/tlk/beoplay-macos-remote-gui/releases
* https://www.beoplayremote.com (which simply links to the above)


Please see [Configuration.md](Configuration.md) for optional settings and how to deal with existing hotkey bindings.


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

