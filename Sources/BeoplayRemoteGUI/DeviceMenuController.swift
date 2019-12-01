//
//  DeviceMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 25/11/2019.
//

import Cocoa
import RemoteCore

class DeviceMenuController : NSObject, NetServiceDelegate {
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
        DispatchQueue.main.async {
            
            for update in updates {
                let menuHasDevice = self.statusMenu.indexOfItem(withRepresentedObject: update.device) > -1
            
                switch update.type {
                case DeviceAction.Add:
                    if menuHasDevice == false {
                        self.addDevice(update.device)
                    }
                case DeviceAction.Remove:
                    self.removeDevice(update.device)
                }
            }
        }
    }

    func removeDevice(_ device: NetService) {
        NSLog("removeDevice: \(device.name)")
        
        if let item = self.getMenuItem(device) {
            self.statusMenu.removeItem(item)
            self.didUpdateDevices()
        }
    }

    func addDevice(_ device: NetService) {
        NSLog("addDevice: \(device.name)")
    
        let item = NSMenuItem(title: device.name, action: #selector(deviceClicked(_:)), keyEquivalent: "")
        item.representedObject = device
        item.target = self
        item.isEnabled = false
        
        self.statusMenu.insertItem(item, at: self.getLocationForNew(item))

        // The menu item is enabled by the delegate when the service address has been resolved
        device.delegate = self
        device.resolve(withTimeout: TimeInterval(5.0))
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        DispatchQueue.main.async {
            NSLog("netServiceDidResolveAddress: \(service.hostName!)")

            let menuItem = self.getMenuItem(service)

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
                return
            }

            if self.getSelected(menuItems).count == 0 {
                if let item = menuItems.filter({ $0.title == defaultDevice }).first {
                    NSLog("connecting to default device")
                    self.connectDevice(item)
                }
            }
        }
    }

    private func getLocationForNew(_ newItem: NSMenuItem) -> Int {
        for item in getDeviceMenuItems() {
            if newItem.title < item.title {
                return statusMenu.index(of: item)
            }
        }
        return self.statusMenu.index(of: self.deviceSeparatorMenuItem)
    }

    private func getDeviceMenuItems() -> [NSMenuItem] {
        self.statusMenu.items.filter { $0.representedObject is NetService }
    }

    private func getSelected(_ items: [NSMenuItem]) -> [NSMenuItem] {
        items.filter { $0.state == NSControl.StateValue.on }
    }
        
    private func getMenuItem(_ device: NetService) -> NSMenuItem? {
        let location = self.statusMenu.indexOfItem(withRepresentedObject: device)
        return self.statusMenu.item(at: location)
    }

    private func connectDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? NetService else {
            return
        }

        NSLog("connectDevice \"\(device.name)\", \(device.hostName!):\(device.port)")

        self.remoteControl.stopVolumeNotifications()
        self.remoteControl.setEndpoint(host: device.hostName!, port: device.port)

        // read the current volume level and receive updates on future volume levels
        self.remoteControl.receiveVolumeNotifications(volumeUpdate: self.volumeLevelViewController.receiveVolumeUpdate,
                                                      connectionUpdate: self.connectionUpdate(state:message:))

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
