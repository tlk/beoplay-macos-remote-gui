//
//  DeviceMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 25/11/2019.
//

import Cocoa
import RemoteCore

class DeviceDelegate : NSObject, NetServiceDelegate {
    private let deviceMenuController: DeviceMenuController

    public init(deviceMenuController: DeviceMenuController) {
        self.deviceMenuController = deviceMenuController
    }

    func netServiceDidResolveAddress(_ device: NetService) {
        DispatchQueue.main.async {
            NSLog("resolved: \(device.name) -> http://\(device.hostName!):\(device.port)")

            guard let menuItem = self.deviceMenuController.getMenuItem(device) else {
                NSLog("resolved: unexpected error")
                return
            }

            menuItem.isEnabled = true

            if let deviceName = UserDefaults.standard.string(forKey: "devices.lastConnected") {
                self.deviceMenuController.tryAutoConnect(deviceName)
            }
        }
    }
}

class DeviceMenuController {
    private let remoteControl: RemoteControl
    private let statusMenu: NSMenu
    private let mainMenuController: MainMenuController
    private let volumeLevelViewController: VolumeLevelViewController
    private let deviceSeparatorMenuItem: NSMenuItem
    private let sourcesMenuController: SourcesMenuController?

    private var deviceDelegate: DeviceDelegate?

    public init(remoteControl: RemoteControl, statusMenu: NSMenu, mainMenuController: MainMenuController, volumeLevelViewController: VolumeLevelViewController, deviceSeparatorMenuItem: NSMenuItem, sourcesMenuController: SourcesMenuController?) {
        self.remoteControl = remoteControl
        self.statusMenu = statusMenu
        self.mainMenuController = mainMenuController
        self.volumeLevelViewController = volumeLevelViewController
        self.deviceSeparatorMenuItem = deviceSeparatorMenuItem
        self.sourcesMenuController = sourcesMenuController
    }

    // This is called from DeviceBrowserDelegate when a device is
    // to be added or removed according to DNS-SD (Bonjour).
    func devicePresenceChanged(_ updates: [DeviceCommand]) {
        DispatchQueue.main.async {
            for update in updates {
                switch update.type {
                case DeviceAction.Add:
                    NSLog("addDevice: \(update.device.name)")

                    guard self.getMenuItem(update.device) == nil else {
                        NSLog("found an existing menu item for this device(!)")
                        return
                    }

                    self.addMenuItem(device: update.device)
                    self.resolveDevices()

                case DeviceAction.Remove:
                    NSLog("removeDevice: \(update.device.name)")

                    guard let item = self.getMenuItem(update.device) else {
                        NSLog("no menu item found for this device(!)")
                        return
                    }

                    if item.state != NSControl.StateValue.off {
                        self.disconnect()
                    }

                    update.device.stop()
                    self.statusMenu.removeItem(item)
                }
            }
        }
    }

    func addMenuItem(device: NetService) {
        func getInsertLocation(_ newItem: NSMenuItem) -> Int {
            for item in self.getDeviceMenuItems() {
                if newItem.title < item.title {
                    return self.statusMenu.index(of: item)
                }
            }
            return self.statusMenu.index(of: self.deviceSeparatorMenuItem)
        }

        let item = NSMenuItem(title: device.name, action: #selector(self.deviceClicked(_:)), keyEquivalent: "")
        item.representedObject = device
        item.target = self
        item.isEnabled = false

        self.statusMenu.insertItem(item, at: getInsertLocation(item))
    }

    func getDeviceMenuItems() -> [NSMenuItem] {
        self.statusMenu.items.filter { $0.representedObject is NetService }
    }

    func getMenuItem(_ device: NetService) -> NSMenuItem? {
        let location = self.statusMenu.indexOfItem(withRepresentedObject: device)

        guard location > -1 else {
            return nil
        }

        return self.statusMenu.item(at: location)
    }

    // Resolve any devices that have not yet been resolved.
    func resolveDevices() {
        let remaining = getDeviceMenuItems().filter { !$0.isEnabled }

        for item in remaining {
            guard let device = item.representedObject as? NetService else {
                NSLog("resolveDevices: unexpected error")
                continue
            }

            resolve(device)
        }
    }
    
    // The device address and port must be resolved before
    // attempting to connect to it.
    //
    // NSNetService.resolve starts a process on the main thread
    // that will call DeviceDelegate.netServiceDidResolveAddress
    // zero or many times when the service address is resolved.
    //
    // DeviceDelegate.netServiceDidResolveAddress is
    // responsible for enabling the menu item.
    func resolve(_ device: NetService) {
        NSLog("resolveDevice: \(device.name)")

        if self.deviceDelegate == nil {
            self.deviceDelegate = DeviceDelegate(deviceMenuController: self)
        }

        device.stop()
        device.delegate = self.deviceDelegate
        device.resolve(withTimeout: 1.0)
    }

    func tryAutoConnect(_ deviceName: String) {
        let menuItems = self.getDeviceMenuItems()

        let selectedItems = menuItems.filter {
            $0.state != NSControl.StateValue.off
        }

        let enabledItems = menuItems.filter {
            $0.isEnabled &&
            $0.title == deviceName
        }

        guard selectedItems.count == 0 else {
            NSLog("auto connect: already connected")
            return
        }
        guard let item = enabledItems.first,
           let device = item.representedObject as? NetService else {
            NSLog("auto connect: no device")
            return
        }

        NSLog("auto connect: \(deviceName)")
        self.setConnecting(item: item)
        self.connect(device: device)
    }

    func setConnecting(item selectedItem: NSMenuItem) {
        let items = self.getDeviceMenuItems()
        for item in items {
            item.state = NSControl.StateValue.off
        }

        selectedItem.state = NSControl.StateValue.mixed
    }

    func setConnected(item: NSMenuItem) {
        item.state = NSControl.StateValue.on
    }

    func connect(device: NetService) {
        NSLog("connect: \(device.name) -> http://\(device.hostName!):\(device.port)")
        UserDefaults.standard.setValue(device.name, forKey: "devices.lastConnected")
        self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)
        self.remoteControl.startNotifications()
        self.volumeLevelViewController.enable()
        self.sourcesMenuController?.enable()
        self.mainMenuController.enableControls()
    }

    func disconnect() {
        NSLog("disconnect")
        self.remoteControl.stopNotifications()
        self.remoteControl.clearEndpoint()
        self.volumeLevelViewController.disable()
        self.sourcesMenuController?.disable()
        self.mainMenuController.disableControls()
    }

    func skipDevice(_ n: Int = 1) {
        let items = self.getDeviceMenuItems().filter { $0.isEnabled }

        guard items.count > 1 else {
            return
        }

        let count = items.count
        let skipBy = n < 0
            ? n % count + count
            : n

        let selected = items.firstIndex { $0.state != NSControl.StateValue.off }
        let current = (selected ?? 0)
        let next = (current + skipBy) % count
        let nextItem = items[next]

        if let device = nextItem.representedObject as? NetService {
            self.disconnect()
            self.setConnecting(item: nextItem)
            self.connect(device: device)
        }
    }

    // The device menu item has a StateValue that reflects
    // the current connection state for the device.
    //
    //     symbol |  StateValue |  meaning
    //    --------|-------------|------------
    //       ―    |  .mixed     |  connecting
    //       ✓    |  .on        |  connected
    //     blank  |  .off       |  not connected
    //
    public func onConnectionChange(_ data: NotificationBridge.DataConnectionNotification) {
        let selectedItems = self.getDeviceMenuItems().filter {
            $0.isEnabled &&
            $0.state != NSControl.StateValue.off
        }

        precondition(selectedItems.count == 0 || selectedItems.count == 1)

        if let item = selectedItems.first {
            if data.state == NotificationSession.ConnectionState.online {
                self.setConnected(item: item)
            } else {
                self.setConnecting(item: item)
            }
        }

        if let message = data.message {
            NSLog("connection state: \(data.state): \(message)")
        } else {
            NSLog("connection state: \(data.state)")
        }
    }

    @IBAction func deviceClicked(_ sender: NSMenuItem) {
        NSLog("deviceClicked")
        self.disconnect()
        self.setConnecting(item: sender)
        self.connect(device: sender.representedObject as! NetService)

        // Keep the menu open to allow the user to select source
        self.mainMenuController.open()
    }
}
