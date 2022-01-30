//
//  DeviceController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 25/11/2019.
//

import Cocoa

enum DeviceAction {
    case Add
    case Remove
}

struct DeviceCommand {
    let type: DeviceAction
    let device: NetService
}

class DeviceBrowserDelegate : NSObject, NetServiceBrowserDelegate {
    private var pendingUpdates = [DeviceCommand]()
    private var deviceMenuController: DeviceMenuController?

    public init(deviceMenuController: DeviceMenuController) {
        self.deviceMenuController = deviceMenuController
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        DispatchQueue.main.async {
            self.pendingUpdates.append(DeviceCommand(type: DeviceAction.Remove, device: service))
            
            NSLog("didRemove: \(service.name), moreComing: \(moreComing)")
            
            if moreComing == false {
                self.devicePresenceChanged()
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        DispatchQueue.main.async {
            self.pendingUpdates.append(DeviceCommand(type: DeviceAction.Add, device: service))
            
            NSLog("didFind: \(service.name), moreComing: \(moreComing)")
            
            if moreComing == false {
                self.devicePresenceChanged()
            }
        }
    }

    private func devicePresenceChanged() {
        NSLog("pending updates: \(self.pendingUpdates.count)")
        let updates = self.pendingUpdates
        self.pendingUpdates = [DeviceCommand]()
        
        self.deviceMenuController?.devicePresenceChanged(updates)
    }
}
