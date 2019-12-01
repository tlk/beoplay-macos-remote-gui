//
//  VolumeLevelViewController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 01/12/2019.
//

import Cocoa
import RemoteCore

public class VolumeLevelViewController : NSObject {
    @IBOutlet weak var volumeLevelMenuItem: NSMenuItem!
    @IBOutlet weak var volumeLevelView: VolumeLevelView!
    @IBOutlet weak var volumeLevelSlider: NSSlider!

    private let remoteControl: RemoteControl
    private var lastVolumeLevel: Int = 0
    private var ignoreReceivedVolumeUpdates = false
    private var debouncer: DispatchWorkItem? = nil

    public init(remoteControl: RemoteControl, volumeLevelMenuItem: NSMenuItem, volumeLevelView: VolumeLevelView, volumeLevelSlider: NSSlider) {
        self.remoteControl = remoteControl
        self.volumeLevelMenuItem = volumeLevelMenuItem
        self.volumeLevelView = volumeLevelView
        self.volumeLevelSlider = volumeLevelSlider

        volumeLevelMenuItem.view = volumeLevelView
    }

    public func receiveVolumeUpdate(vol: Int?) {
        DispatchQueue.main.async {
            if (vol == nil) {
                return
            }

            if self.ignoreReceivedVolumeUpdates {
                NSLog("receive: \(vol!)  (ignored!)")
            } else {
                self.lastVolumeLevel = vol!
                self.volumeLevelSlider.integerValue = self.lastVolumeLevel
                NSLog("receive: \(self.lastVolumeLevel)")
            }
        }
    }

    private func sendVolumeUpdate(vol: Int) {
        self.remoteControl.setVolume(volume: vol)
        NSLog("send: \(vol)")
    }

    public func sliderMoved(_ sender: NSSlider) {
        func debounce(seconds: TimeInterval, function: @escaping () -> ()) {
            self.debouncer?.cancel()
            self.debouncer = DispatchWorkItem {
                function()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: self.debouncer!)
        }

        let eventType = sender.window?.currentEvent?.type
        let volume = sender.integerValue

        if self.lastVolumeLevel != volume {
            self.lastVolumeLevel = volume

            if !self.ignoreReceivedVolumeUpdates {
                NSLog("user is moving the slider (preventing slider wobbliness)")
                self.ignoreReceivedVolumeUpdates = true
            }

            self.sendVolumeUpdate(vol: volume)

            debounce(seconds: 1) {
                NSLog("user is no longer moving the slider")
                self.ignoreReceivedVolumeUpdates = false
            }
        }

        if eventType == NSEvent.EventType.leftMouseUp {
            self.ignoreReceivedVolumeUpdates = false

            // close the menu
//            self.statusMenu.cancelTracking()
        }
    }

}
