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
    @IBOutlet weak var volumeLevelMenuItem: NSMenuItem!
    @IBOutlet weak var sourcesMenuItem: NSMenuItem!
    @IBOutlet weak var tuneinMenuItem: NSMenuItem!
    @IBOutlet weak var deviceSeparatorMenuItem: NSMenuItem!
    @IBOutlet weak var separatorMenuItem: NSMenuItem!

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var deviceController = DeviceController()
    private var remoteControl = RemoteControl()
    private var lastVolumeLevel: Int = 0
    private var ignoreReceivedVolumeUpdates = false
    private var debouncer: DispatchWorkItem? = nil

    override func awakeFromNib() {
        statusItem.button?.title = UserDefaults.standard.string(forKey: "app.title") ?? "BeoplayRemote"
        statusItem.menu = statusMenu
        volumeLevelMenuItem.view = volumeLevelView

        if UserDefaults.standard.bool(forKey: "hotkeys.enabled") {
            setupHotkeys()
        }

        if UserDefaults.standard.bool(forKey: "tuneIn.enabled") {
            setupTuneIn()
        }

        deviceController.menuController = DeviceMenuController(self)
        remoteControl.startDiscovery(delegate: deviceController)
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
        self.remoteControl.setVolume(volume: vol)
        NSLog("send: \(vol)")
    }

    private func setupHotkeys() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if !isTrusted {
            NSLog("hotkeys setup failed:  required permission to 'control this computer using accessibility features' is missing")
        } else {
            NSLog("hotkeys setup")

            let F11 = "103"
            let F12 = "111"
            let defaultStep = 4

            let volumedownKey = UInt16(UserDefaults.standard.string(forKey: "hotkeys.volumedownKey") ?? F11, radix: 10)
            let volumeupKey   = UInt16(UserDefaults.standard.string(forKey: "hotkeys.volumeupKey")   ?? F12, radix: 10)
            let step: Int = UserDefaults.standard.integer(forKey: "hotkeys.step") > 0 ?
                            UserDefaults.standard.integer(forKey: "hotkeys.step") : defaultStep

            NSLog("volumedownKey: \(volumedownKey!), volumeupKey: \(volumeupKey!), step: \(step)")

            func adjust(_ volume: Int) {
                NSLog("hotkey: adjusting volume")
                self.volumeLevelSlider.integerValue = volume
                self.sendVolumeUpdate(vol: volume)
            }

            NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { (event) in
                let volume = self.volumeLevelSlider.integerValue

                switch(event.keyCode) {
                case volumedownKey:
                    adjust(volume - step)
                    break
                case volumeupKey:
                    adjust(volume + step)
                    break
                default:
                    break
                }
            }
        }
    }

    private func refreshSources() {
        NSLog("refresh sources")

        self.remoteControl.getEnabledSources { (sources: [BeoplaySource]) in
            var hideTypes: [String] = []

            if let tmp = UserDefaults.standard.array(forKey: "sources.hideTypes") {
                hideTypes = tmp.map { ($0 as! String).lowercased() }
            }

            self.sourcesMenuItem.submenu?.removeAllItems()
            self.sourcesMenuItem.isHidden = false
            self.separatorMenuItem.isHidden = false

            var hasTuneIn = false
            
            for source in sources {
                if hideTypes.contains(source.sourceType.lowercased()) {
                    continue
                }

                if source.sourceType == "TUNEIN" {
                    hasTuneIn = true
                }

                var name: String
                if source.borrowed {
                    name = "\(source.friendlyName) (\(source.productFriendlyName))"
                } else {
                    name = source.friendlyName
                }

                let item = NSMenuItem(title: name, action: #selector(self.setSource(_:)), keyEquivalent: "")
                item.representedObject = source.id
                item.target = self
                item.isEnabled = true
                self.sourcesMenuItem.submenu?.addItem(item)
                NSLog("source id: \(source.id), source name: \(name)")
            }

            if UserDefaults.standard.bool(forKey: "tuneIn.enabled") {
                self.tuneinMenuItem.isHidden = !hasTuneIn
            }
        }
    }

    private func setupTuneIn() {
        let order = UserDefaults.standard.array(forKey: "tuneIn.order")!
        let stations = UserDefaults.standard.dictionary(forKey: "tuneIn.stations")!

        self.tuneinMenuItem.isHidden = false
        self.separatorMenuItem.isHidden = false

        for id in order {
            let name = stations[id as! String] as! String
            let item = NSMenuItem(title: name, action: #selector(tuneIn(_:)), keyEquivalent: "")
            item.representedObject = id
            item.target = self
            item.isEnabled = true
            self.tuneinMenuItem.submenu?.addItem(item)
            NSLog("tuneIn radio station id: \(id), station name: \(name)")
        }
    }

    @IBAction func setSource(_ sender: NSMenuItem) {
        let id = sender.representedObject as! String
        self.remoteControl.setSource(id: id)
        NSLog("setSource: \(id)")
    }

    @IBAction func tuneIn(_ sender: NSMenuItem) {
        let id = sender.representedObject as! String
        self.remoteControl.tuneIn(id: id, name: sender.title)
        NSLog("tuneIn: \(id)")
    }

    @IBAction func sliderMoved(_ sender: NSSlider) {
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
            self.statusMenu.cancelTracking()
        }
    }

    func connectDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? NetService else {
            return
        }

        NSLog("connectDevice \"\(device.name)\", \(device.hostName!):\(device.port)")

        self.remoteControl.stopVolumeNotifications()
        self.remoteControl = RemoteControl()
        self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)
        self.setupVolumeUpdateReceiver()

        self.deviceController.menuController?.selectDeviceMenuItem(sender)

        if UserDefaults.standard.bool(forKey: "sources.enabled") {
            self.refreshSources()
        }
    }

    @IBAction func deviceClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.connectDevice(sender)
            NSLog("device")
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
