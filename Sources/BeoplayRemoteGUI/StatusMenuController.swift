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
    private var deviceMenuItems: [NSMenuItem] = []

    private var remoteControl = RemoteControl()
    private var lastVolumeLevel: Int = 0
    private var ignoreReceivedVolumeUpdates = false

    override func awakeFromNib() {
        statusItem.button?.title = "BeoplayRemote"
        statusItem.menu = statusMenu

        volumeLevelMenuItem = statusMenu.item(withTitle: "VolumeSlider")
        volumeLevelMenuItem.view = volumeLevelView

        discoverDevices()
    }

    private func discoverDevices() {
        var first = true

        func foundDevice(_ device: NetService) {
            let item = addDeviceMenuItem(device)
            self.deviceMenuItems.append(item)
            if first {
                first = false
                item.state = NSControl.StateValue.on
                self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)
                setupVolumeUpdateReceiver()
            }
        }

        func addDeviceMenuItem(_ service: NetService) -> NSMenuItem {
            let location = statusMenu.indexOfItem(withTitle: "deviceSeparator")
            let item = NSMenuItem(title: service.name, action: #selector(deviceClicked(_:)), keyEquivalent: "")
            item.representedObject = service
            item.target = self
            item.isEnabled = true
            statusMenu.insertItem(item, at: location)
            return item
        }

        self.remoteControl.discover({}, callback: foundDevice)
    }

    private func setupVolumeUpdateReceiver() {
        // read the current volume level and receive updates on future volume levels
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.receiveVolumeNotifications(volumeUpdate: self.receiveVolumeUpdate) { (state, message) in
                if message == nil {
                    NSLog("connection state: \(state)")
                } else {
                    NSLog("connection state: \(state): \(message!)")
                }
            }
        }
    }

    private func receiveVolumeUpdate(vol: Int?) {
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
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.setVolume(volume: vol)
            NSLog("send: \(vol)")
        }
    }

    @IBAction func sliderMoved(_ sender: NSSlider) {
        if sender.window?.currentEvent?.type == NSEvent.EventType.leftMouseDown {
            self.ignoreReceivedVolumeUpdates = true
        }

        if sender.window?.currentEvent?.type == NSEvent.EventType.leftMouseUp {
            self.ignoreReceivedVolumeUpdates = false

            // close the dropdown menu
            self.statusMenu.cancelTracking()
        }

        if self.lastVolumeLevel != sender.integerValue {
            self.lastVolumeLevel = sender.integerValue
            self.sendVolumeUpdate(vol: sender.integerValue)
        }
    }

    @IBAction func deviceClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            let device = sender.representedObject as! NetService
            NSLog("deviceClicked, \"\(device.name)\", \(device.hostName!):\(device.port)")

            self.remoteControl.stopVolumeNotifications()
            self.remoteControl = RemoteControl()
            self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)
            self.setupVolumeUpdateReceiver()

            for item in self.deviceMenuItems {
                item.state = NSControl.StateValue.off
            }

            sender.state = NSControl.StateValue.on
        }
    }

    @IBAction func playClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.play()
            NSLog("play")
        }
    }

    @IBAction func pauseClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.pause()
            NSLog("pause")
        }
    }

    @IBAction func forwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.forward()
            NSLog("forward")
        }
    }

    @IBAction func backwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.backward()
            NSLog("backward")
        }
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
        NSLog("quit")
    }
}
