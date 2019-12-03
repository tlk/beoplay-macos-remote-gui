//
//  DeviceMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 25/11/2019.
//

import Cocoa
import RemoteCore

class DeviceMenuController : NSObject, NetServiceDelegate {
    private let resolveTimeout = 5.0
    private let statusMenu: NSMenu
    private let remoteControl: RemoteControl
    private let deviceSeparatorMenuItem: NSMenuItem
    private let volumeLevelViewController: VolumeLevelViewController
    private let sourcesMenuController: SourcesMenuController

    public init(remoteControl: RemoteControl, statusMenu: NSMenu, deviceSeparatorMenuItem: NSMenuItem, volumeLevelViewController: VolumeLevelViewController, sourcesMenuController: SourcesMenuController) {
        self.remoteControl = remoteControl
        self.statusMenu = statusMenu
        self.deviceSeparatorMenuItem = deviceSeparatorMenuItem
        self.volumeLevelViewController = volumeLevelViewController
        self.sourcesMenuController = sourcesMenuController
    }

    public func connectionUpdate(state: RemoteNotificationsSession.ConnectionState, message: String?) {
        DispatchQueue.main.async {
            let item = self.getDeviceMenuItems().filter({ $0.isEnabled && $0.state != NSControl.StateValue.off}).first
            item?.state =
                state == RemoteNotificationsSession.ConnectionState.online
                    ? NSControl.StateValue.on
                    : NSControl.StateValue.mixed
        }

        if message == nil {
            NSLog("connection state: \(state)")
        } else {
            NSLog("connection state: \(state): \(message!)")
        }
    }

    public func selectDeviceMenuItem(_ selectedItem: NSMenuItem) {
        DispatchQueue.main.async {
            let items = self.getDeviceMenuItems()
            for item in items {
                item.state = NSControl.StateValue.off
            }

            selectedItem.state = NSControl.StateValue.on
        }
    }

    public func handleDeviceUpdates(_ updates: [DeviceCommand]) {
        func removeDevice(_ device: NetService) {
            NSLog("removeDevice: \(device.name)")
            
            if let item = self.getMenuItem(device) {
                self.statusMenu.removeItem(item)
                self.didUpdateDevices()
            }
        }

        func addDevice(_ device: NetService) {

            func getLocationForNew(_ newItem: NSMenuItem) -> Int {
                for item in getDeviceMenuItems() {
                    if newItem.title < item.title {
                        return statusMenu.index(of: item)
                    }
                }
                return self.statusMenu.index(of: self.deviceSeparatorMenuItem)
            }

            NSLog("addDevice: \(device.name)")

            let item = NSMenuItem(title: device.name, action: #selector(deviceClicked(_:)), keyEquivalent: "")
            item.representedObject = device
            item.target = self
            item.isEnabled = false

            self.statusMenu.insertItem(item, at: getLocationForNew(item))

            // The menu item is enabled by the delegate when the service address has been resolved
            device.delegate = self
            device.resolve(withTimeout: self.resolveTimeout)
        }

        DispatchQueue.main.async {
            for update in updates {
                let menuHasDevice = self.statusMenu.indexOfItem(withRepresentedObject: update.device) > -1

                switch update.type {
                case DeviceAction.Add:
                    if menuHasDevice == false {
                        addDevice(update.device)
                    }
                case DeviceAction.Remove:
                    removeDevice(update.device)
                }
            }
        }
    }

    func netServiceDidResolveAddress(_ device: NetService) {
        DispatchQueue.main.async {
            NSLog("netServiceDidResolveAddress: \(device.hostName!)")

            let menuItem = self.getMenuItem(device)

            menuItem?.isEnabled = true
            self.didUpdateDevices()
        }
    }

    func didUpdateDevices() {
        let menuItems = self
            .getDeviceMenuItems()
            .filter { $0.isEnabled }
        
        switch menuItems.count {
        case 0:
            NSLog("no devices available")
            self.sourcesMenuController.noDevicesAvailable()
        default:
            guard let defaultDevice = UserDefaults.standard.string(forKey: "devices.default") else {
                // Do nothing unless a default device is configured
                return
            }

            let selectedItems = menuItems.filter { $0.state == NSControl.StateValue.on }

            if selectedItems.count == 0 {
                if let item = menuItems.filter({ $0.title == defaultDevice }).first {
                    NSLog("connecting to default device")
                    self.connectDevice(item)
                }
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

    func connectDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? NetService else {
            NSLog("connectDevice panic")
            return
        }

        NSLog("connectDevice \"\(device.name)\", \(device.hostName!):\(device.port)")

        self.remoteControl.stopNotifications()
        self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)
        self.remoteControl.startNotifications()
        self.selectDeviceMenuItem(sender)

        if UserDefaults.standard.bool(forKey: "sources.enabled") {
            self.sourcesMenuController.reload()
        }
    }

    @IBAction func deviceClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.connectDevice(sender)
            NSLog("device")
        }
    }
}
