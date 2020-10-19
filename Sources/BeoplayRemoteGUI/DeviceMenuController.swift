//
//  DeviceMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 25/11/2019.
//

import Cocoa
import RemoteCore

class DeviceMenuController : NSObject, NetServiceDelegate {
    private let queue = DispatchQueue.init(label: "serialized-device-connection")
    private let remoteControl: RemoteControl
    private let statusMenu: NSMenu
    private let mainMenuController: MainMenuController
    private let volumeLevelViewController: VolumeLevelViewController
    private let deviceSeparatorMenuItem: NSMenuItem
    private let sourcesMenuController: SourcesMenuController?

    public init(remoteControl: RemoteControl, statusMenu: NSMenu, mainMenuController: MainMenuController, volumeLevelViewController: VolumeLevelViewController, deviceSeparatorMenuItem: NSMenuItem, sourcesMenuController: SourcesMenuController?) {
        self.remoteControl = remoteControl
        self.statusMenu = statusMenu
        self.mainMenuController = mainMenuController
        self.volumeLevelViewController = volumeLevelViewController
        self.deviceSeparatorMenuItem = deviceSeparatorMenuItem
        self.sourcesMenuController = sourcesMenuController
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

    func netServiceDidResolveAddress(_ device: NetService) {
        DispatchQueue.main.async {
            guard let menuItem = self.getMenuItem(device), !menuItem.isEnabled else {
                // When the resolve process runs with an indefinite duration it
                // may call this method repeatedly. However, a single update is
                // all that is needed so let us keep this method idempotent.
                return
            }

            NSLog("resolved: \(device.name) -> http://\(device.hostName!):\(device.port)")
            menuItem.isEnabled = true
            self.connectDefaultDevice()
        }
    }

    func connectDefaultDevice() {
        guard let defaultDevice = UserDefaults.standard.string(forKey: "devices.default") else {
            return
        }

        let menuItems = self.getDeviceMenuItems()

        let selectedItems = menuItems.filter {
            $0.state != NSControl.StateValue.off
        }

        let enabledItems = menuItems.filter {
            $0.isEnabled &&
            $0.title == defaultDevice
        }

        guard selectedItems.count == 0, let item = enabledItems.first else {
            return
        }

        if let device = item.representedObject as? NetService {
            NSLog("connecting to default device")
            self.setConnecting(item: item)
            self.connect(device: device)
        }
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

                    // The device IP address must be resolved before the menu item is
                    // enabled and before attempting to connect to it.
                    //
                    // The call to update.device.resolve will start a resolve process
                    // that will call NSNetServiceDelegate.netServiceDidResolveAddress
                    // zero or many times when the service address is resolved.
                    //
                    // The delegate netServiceDidResolveAddress() method is
                    // responsible for enabling the menu item.
                    //
                    // From NSNetService.resolve(withTimeout):
                    //      The maximum number of seconds to attempt a resolve.
                    //      A value of 0.0 indicates no timeout and a resolve
                    //      process of indefinite duration.

                    let indefinite = 0.0
                    self.addMenuItem(device: update.device)
                    update.device.delegate = self
                    update.device.resolve(withTimeout: indefinite)

                case DeviceAction.Remove:
                    NSLog("removeDevice: \(update.device.name)")

                    guard let item = self.getMenuItem(update.device) else {
                        NSLog("no menu item found for this device(!)")
                        return
                    }

                    if item.state == NSControl.StateValue.off {
                        self.statusMenu.removeItem(item)
                    } else {
                        self.disconnect()
                        self.statusMenu.removeItem(item)
                        self.connectDefaultDevice()
                    }
                }
            }
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
