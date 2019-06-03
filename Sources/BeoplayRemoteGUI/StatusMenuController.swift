//
//  StatusMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 03/06/2019.
//

import Cocoa
import RemoteCore

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var volumeLevelView: VolumeLevelView!
    @IBOutlet weak var volumeLevelSlider: NSSlider!
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var volumeLevelMenuItem: NSMenuItem!

    private let remoteControl = RemoteControl()
    private var volume: Int = 0
    private var ignoreReceivedVolumeUpdates = false

    override func awakeFromNib() {
        statusItem.button?.title = "BeoplayRemote"
        statusItem.menu = statusMenu
        
        volumeLevelMenuItem = statusMenu.item(withTitle: "VolumeSlider")
        volumeLevelMenuItem.view = volumeLevelView
        
        setupVolumeUpdateReceiver()
    }

    private func setupVolumeUpdateReceiver() {
        // read the current volume level
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.getVolume(callback: self.receiveVolumeUpdate)
        }
        
        // receive updates on future volume levels
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.receiveVolumeNotifications(volumeUpdate: self.receiveVolumeUpdate) { state in
                NSLog("connection state: \(state)")
            }
        }
    }

    private func receiveVolumeUpdate(vol: Int) {
        DispatchQueue.main.async {
            if self.ignoreReceivedVolumeUpdates {
                NSLog("receive: \(vol)  (ignored!)")
            } else {
                self.volume = vol
                self.volumeLevelSlider.integerValue = vol
                NSLog("receive: \(vol)")
            }
        }
    }
    
    private func sendVolumeUpdate(vol: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.setVolume(volume: vol)
            NSLog("send: \(vol)")
        }
    }

    @IBAction func sliderMoved(_ sender: NSSlider) {
        if sender.window?.currentEvent?.type == NSEvent.EventType.leftMouseDown {
            self.ignoreReceivedVolumeUpdates = true
        }
        
        if sender.window?.currentEvent?.type == NSEvent.EventType.leftMouseUp {
            self.ignoreReceivedVolumeUpdates = false
            self.statusMenu.cancelTracking()
        }
        
        if self.volume != sender.integerValue {
            self.volume = sender.integerValue
            self.sendVolumeUpdate(vol: sender.integerValue)
        }
    }
    
    @IBAction func playClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.play()
            NSLog("play")
        }
    }
    
    @IBAction func pauseClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.pause()
            NSLog("pause")
        }
    }
    
    @IBAction func forwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.forward()
            NSLog("forward")
        }
    }
    
    @IBAction func backwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.remoteControl.backward()
            NSLog("backward")
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
        NSLog("quit")
    }
}
