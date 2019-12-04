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
    private let resolveTimeout = 5.0
    private let remoteControl: RemoteControl
    private let statusMenu: NSMenu
    private let volumeLevelViewController: VolumeLevelViewController
    private let deviceSeparatorMenuItem: NSMenuItem
    private let sourcesMenuController: SourcesMenuController?

    public init(remoteControl: RemoteControl, statusMenu: NSMenu, volumeLevelViewController: VolumeLevelViewController, deviceSeparatorMenuItem: NSMenuItem, sourcesMenuController: SourcesMenuController?) {
        self.remoteControl = remoteControl
        self.statusMenu = statusMenu
        self.volumeLevelViewController = volumeLevelViewController
        self.deviceSeparatorMenuItem = deviceSeparatorMenuItem
        self.sourcesMenuController = sourcesMenuController
    }

    public func addObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name.onConnectionChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            guard let data = notification.userInfo?["data"] as? NotificationBridge.DataConnectionNotification else {
                return
            }

            DispatchQueue.main.async {
                if let item = self.getDeviceMenuItems().filter({ $0.isEnabled && $0.state != NSControl.StateValue.off}).first {
                    if data.state == NotificationSession.ConnectionState.online {
                        self.setConnected(item: item)
                    } else {
                        self.setConnecting(item: item)
                    }
                }
            }

            if data.message == nil {
                NSLog("connection state: \(data.state)")
            } else {
                NSLog("connection state: \(data.state): \(data.message!)")
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

    func netServiceDidResolveAddress(_ device: NetService) {
        DispatchQueue.main.async {
            NSLog("resolved: \(device.name) -> http://\(device.hostName!):\(device.port)")
            self.getMenuItem(device)?.isEnabled = true
            self.connectDefaultDevice()
        }
    }

    func connectDefaultDevice() {
        guard let defaultDevice = UserDefaults.standard.string(forKey: "devices.default") else {
            return
        }

        let menuItems = self.getDeviceMenuItems()
        let enabledItems = menuItems.filter { $0.isEnabled }
        let selectedItems = menuItems.filter { $0.state != NSControl.StateValue.off }

        if selectedItems.count == 0 {
            if let item = enabledItems.filter({ $0.title == defaultDevice }).first {
                NSLog("connecting to default device")
                self.setConnecting(item: item)
                self.connect(device: item.representedObject as! NetService)
            }
        }
    }

    func getDeviceMenuItems() -> [NSMenuItem] {
        self.statusMenu.items.filter { $0.representedObject is NetService }
    }
        
    func getMenuItem(_ device: NetService) -> NSMenuItem? {
        let location = self.statusMenu.indexOfItem(withRepresentedObject: device)
        return self.statusMenu.item(at: location)
    }

    // The device menu item has a StateValue that reflects
    // the current connection state for the device.
    //
    //     symbol |  StateValue |  meaning
    //    --------|-------------|------------
    //       ―    |  .mixed     |  connecting
    //       ✓    |  .on        |  connected
    //
    // This is updated via the notification event
    // Notification.Name.onConnectionChange
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

        // TODO: enableStatusMenuControls()
    }

    func disconnect() {
        NSLog("disconnect")
        self.remoteControl.stopNotifications()
        self.remoteControl.clearEndpoint()
        self.volumeLevelViewController.disable()
        self.sourcesMenuController?.disable()

        // TODO: disableStatusMenuControls()
    }

    func devicePresenceChanged(_ updates: [DeviceCommand]) {
        DispatchQueue.main.async {
            for update in updates {
                switch update.type {
                case DeviceAction.Add:
                    NSLog("addDevice: \(update.device.name)")

                    let menuHasDevice = self.statusMenu.indexOfItem(withRepresentedObject: update.device) > -1
                    guard menuHasDevice == false else {
                        // It does not make sense to represent the same device more than once
                        return
                    }

                    self.addMenuItem(device: update.device)

                    // The menu item is enabled when the service address has been resolved
                    // See netServiceDidResolveAddress
                    update.device.delegate = self
                    update.device.resolve(withTimeout: self.resolveTimeout)

                case DeviceAction.Remove:
                    NSLog("removeDevice: \(update.device.name)")

                    guard let item = self.getMenuItem(update.device) else {
                        return
                    }

                    if item.state != NSControl.StateValue.off {
                        self.disconnect()
                        self.statusMenu.removeItem(item)
                        self.connectDefaultDevice()
                    } else {
                        self.statusMenu.removeItem(item)
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
    }
}
