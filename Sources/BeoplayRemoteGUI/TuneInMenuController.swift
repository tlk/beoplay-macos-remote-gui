//
//  TuneInMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 01/12/2019.
//

import Cocoa
import RemoteCore

public class TuneInMenuController {
    private let remoteControl: RemoteControl
    private let tuneInMenuItem: NSMenuItem
    private var hasAnyStations = false

    public init(remoteControl: RemoteControl, tuneInMenuItem: NSMenuItem) {
        self.remoteControl = remoteControl
        self.tuneInMenuItem = tuneInMenuItem
    }

    public func setup() {
        let order = UserDefaults.standard.array(forKey: "tuneIn.order")!
        let stations = UserDefaults.standard.dictionary(forKey: "tuneIn.stations")!

        DispatchQueue.main.async {
            for id in order {
                self.hasAnyStations = true
                let name = stations[id as! String] as! String
                let item = NSMenuItem(title: name, action: #selector(self.tuneIn(_:)), keyEquivalent: "")
                item.representedObject = id
                item.target = self
                item.isEnabled = true
                self.tuneInMenuItem.submenu?.addItem(item)
                NSLog("tuneIn radio station id: \(id), station name: \(name)")
            }

            self.tuneInMenuItem.isHidden = false
        }
    }

    public func deviceHasTuneInSource(_ hasSource: Bool) {
        self.tuneInMenuItem.isHidden = !hasSource || !self.hasAnyStations
    }

    @IBAction func tuneIn(_ sender: NSMenuItem) {
        let id = sender.representedObject as! String
        self.remoteControl.tuneIn(id: id, name: sender.title)
        NSLog("tuneIn: \(id), \(sender.title)")
    }
}
