//
//  HotkeysController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 01/12/2019.
//

import Cocoa
import RemoteCore
import HotKey

class HotkeysController {
    private let remoteControl: RemoteControl
    private let deviceMenuController: DeviceMenuController
    private let sourcesMenuController: SourcesMenuController

    private var lastMuted: Bool?
    private var lastPlaybackState: RemoteCore.DeviceState?

    private enum Command : String {
        case PrevDevice,
             NextDevice,
             Leave,
             Join,
             PrevSource,
             NextSource,
             Back,
             TogglePlayPause,
             Next,
             ToggleMute,
             VolumeDown,
             VolumeUp
    }

    private let defaultConfiguration = [
        Command.PrevDevice:       Key.f1,
        Command.NextDevice:       Key.f2,
        Command.Leave:            Key.f3,
        Command.Join :            Key.f4,
        Command.PrevSource:       Key.f5,
        Command.NextSource:       Key.f6,
        Command.Back:             Key.f7,
        Command.TogglePlayPause:  Key.f8,
        Command.Next:             Key.f9,
        Command.ToggleMute:       Key.f10,
        Command.VolumeDown:       Key.f11,
        Command.VolumeUp:         Key.f12
    ]

    private var hotkeys = [HotKey]()
    private let defaultVolumeStep = 4

    init(remoteControl: RemoteControl, deviceMenuController: DeviceMenuController, sourcesMenuController: SourcesMenuController) {
        self.remoteControl = remoteControl
        self.deviceMenuController = deviceMenuController
        self.sourcesMenuController = sourcesMenuController

        let volumeStep: Int = UserDefaults.standard.integer(forKey: "hotkeys.VolumeStep") > 0 ?
                              UserDefaults.standard.integer(forKey: "hotkeys.VolumeStep") : defaultVolumeStep

        NSLog("hotkeys.VolumeStep: \(volumeStep)")

        defaultConfiguration.forEach { command, defaultKey in
            guard UserDefaults.standard.string(forKey: "hotkeys.\(command)") != "disabled" else {
                NSLog("hotkeys.\(command) -- disabled!")
                return
            }

            let key = UserDefaults.standard.string(forKey: "hotkeys.\(command)") == nil
                ? defaultKey
                : Key.init(string: UserDefaults.standard.string(forKey: "hotkeys.\(command)")!) ?? defaultKey

            let hotkey = HotKey(key: key, modifiers: [])
            hotkey.keyDownHandler = getHandler(key: key, command: command, volumeStep: volumeStep)
            hotkeys.append(hotkey)

            NSLog("hotkeys.\(command): \(key.description)")
        }
    }

    private func getHandler(key: Key, command: Command, volumeStep: Int) -> (() -> Void) {
        return { [weak self] in

            NSLog("hotkey: \(key.description), command: \(command)")

            switch command {
                case Command.PrevDevice:
                    self?.deviceMenuController.skipDevice(-1)
                    break
                case Command.NextDevice:
                    self?.deviceMenuController.skipDevice(1)
                    break
                case Command.Leave:
                    self?.remoteControl.leave()
                    break
                case Command.Join:
                    self?.remoteControl.join()
                    break
                case Command.PrevSource:
                    self?.sourcesMenuController.skipSource(-1)
                    break
                case Command.NextSource:
                    self?.sourcesMenuController.skipSource(1)
                    break
                case Command.Back:
                    self?.remoteControl.back()
                    break
                case Command.TogglePlayPause:
                    if self?.lastPlaybackState == RemoteCore.DeviceState.play {
                        self?.remoteControl.pause()
                    } else {
                        self?.remoteControl.play()
                    }
                    break
                case Command.Next:
                    self?.remoteControl.next()
                    break
                case Command.ToggleMute:
                    if self?.lastMuted == true {
                        self?.remoteControl.unmute()
                    } else {
                        self?.remoteControl.mute()
                    }
                    break
                case Command.VolumeDown:
                    self?.remoteControl.adjustVolume(delta: -volumeStep)
                    break
                case Command.VolumeUp:
                    self?.remoteControl.adjustVolume(delta: volumeStep)
                    break
            }
        }
    }

    public func onVolumeChange(_ data: RemoteCore.Volume) {
        self.lastMuted = data.muted
    }

    public func onProgress(_ data: RemoteCore.Progress) {
        self.lastPlaybackState = data.state
    }
}
