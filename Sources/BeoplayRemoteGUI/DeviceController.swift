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

class DeviceController : NSObject, NetServiceBrowserDelegate {
    private let q = DispatchQueue(label: "beoplay-device-manager")
    private var pendingUpdates = [DeviceCommand]()
    
    public var menuController: DeviceMenuController?

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.q.async {
            self.pendingUpdates.append(DeviceCommand(type: DeviceAction.Remove, device: service))
            
            if moreComing == false {
                self.handleDeviceUpdates()
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        self.q.async {
            self.pendingUpdates.append(DeviceCommand(type: DeviceAction.Add, device: service))
            
            NSLog("didFind: \(service.name), moreComing: \(moreComing)")
            
            if moreComing == false {
                self.handleDeviceUpdates()
            }
        }
    }

    private func handleDeviceUpdates() {
        NSLog("pending updates: \(self.pendingUpdates.count)")
        let updates = self.pendingUpdates
        self.pendingUpdates = [DeviceCommand]()
        
        self.menuController?.handleDeviceUpdates(updates)
    }
}
