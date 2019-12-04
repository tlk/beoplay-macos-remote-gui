//
//  HotkeysController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 01/12/2019.
//

import Cocoa
import RemoteCore

public class HotkeysController {
    private let remoteControl: RemoteControl
    private var eventMonitor: Any?

    private enum Command : String {
        case Leave, Join, PrevSource, NextSource, Back, TogglePlayPause, Next, Mute, VolumeDown, VolumeUp
    }

    private enum Hotkey : String {
        case F1  = "122"
        case F2  = "120"
        case F3  =  "99"
        case F4  = "118"
        case F5  =  "96"
        case F6  =  "97"
        case F7  =  "98"
        case F8  = "100"
        case F9  = "101"
        case F10 = "109"
        case F11 = "103"
        case F12 = "111"
    }

    private let defaultConfiguration = [
        Hotkey.F1  : Command.Leave,
        Hotkey.F2  : Command.Join,
        Hotkey.F5  : Command.PrevSource,
        Hotkey.F6  : Command.NextSource,
        Hotkey.F7  : Command.Back,
        Hotkey.F8  : Command.TogglePlayPause,
        Hotkey.F9  : Command.Next,
        Hotkey.F10 : Command.Mute,
        Hotkey.F11 : Command.VolumeDown,
        Hotkey.F12 : Command.VolumeUp
    ]

    public init(remoteControl: RemoteControl) {
        self.remoteControl = remoteControl

        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        guard isTrusted else {
            NSLog("hotkeys setup failed:  required permission to 'control this computer using accessibility features' is missing")
            return
        }

        let defaultVolumeStep = 4
        let volumeStep: Int = UserDefaults.standard.integer(forKey: "hotkeys.VolumeStep") > 0 ?
                              UserDefaults.standard.integer(forKey: "hotkeys.VolumeStep") : defaultVolumeStep

        NSLog("hotkeys.VolumeStep: \(volumeStep)")

        let hotkeyMap = Dictionary(uniqueKeysWithValues:
            defaultConfiguration.compactMap() { hotkey, command -> (UInt16, Command)? in
                let strKeycode = UserDefaults.standard.string(forKey: "hotkeys.\(command)") ?? hotkey.rawValue
                if let keycode = UInt16(strKeycode, radix: 10) {
                    NSLog("hotkeys.\(command): \(strKeycode)")
                    return (keycode, command)
                } else {
                    return nil
                }
            }
        )

        eventMonitor = addGlobalMonitor(hotkeyMap, volumeStep)
    }


    private func addGlobalMonitor(_ hotkeyMap: [UInt16 : HotkeysController.Command], _ volumeStep: Int) -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { (event) in
            guard let command = hotkeyMap[event.keyCode] else {
                return
            }

            NSLog("hotkey command: \(command)")

            switch(command) {
            case Command.Leave:
                self.remoteControl.leave()
                break
            case Command.Join:
                self.remoteControl.join()
                break
            case Command.PrevSource:
                NSLog("Not implemented")
//                self.setSource(self.sourcesMenuItem!.submenu!.item(at: 2) as! NSMenuItem)
                break
            case Command.NextSource:
                NSLog("Not implemented")
//                self.setSource(self.sourcesMenuItem!.submenu!.item(at: 3) as! NSMenuItem)
                break
            case Command.Back:
                self.remoteControl.back()
                break
            case Command.TogglePlayPause:
                NSLog("Not implemented")
                break
            case Command.Next:
                self.remoteControl.next()
                break
            case Command.Mute:
                NSLog("Not implemented")
                break
            case Command.VolumeDown:
                self.remoteControl.adjustVolume(delta: -volumeStep)
                break
            case Command.VolumeUp:
                self.remoteControl.adjustVolume(delta: volumeStep)
                break
            }
        }
    }
}
