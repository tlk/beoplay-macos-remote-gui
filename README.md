# BeoplayRemoteGUI.app

This is an unofficial menu bar app for Mac OS to remote control network enabled beoplay loudspeakers such as the Beoplay M5.

## Example

![Screenshot](./screenshot.png)

The menu bar has basic support for play/pause, forward/backward (fx for shuffling between favourite radio stations). The volume level can be adjusted and works well with volume adjustments made directly on the loudspeakers, through the original Bang&Olufsen iOS app, etc.

## Building
- fetch dependencies with `swift package update`
- `open beoplay-macos-remote-gui.xcodeproj` and build the project with XCode.

## Configuration
The loudspeakers are accessible through a web interface (fx http://192.168.1.20/index.fcgi) and the command line tool needs to know this IP address. You will have to do some discovery yourself if you do not already know what this is. Tip: check your router for a list of connected devices.

When you know the IP address of the beoplay loudspeakers it must be stored in the BeoplayRemoteGUI.app user preferences:

```
defaults write dk.thomaslkjeldsen.BeoplayRemoteGUI host 192.168.1.20     # (<-- change this to the loudspeakers ip address)
```

