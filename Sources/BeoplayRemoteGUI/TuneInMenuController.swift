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
                let item = NSMenuItem(title: name, action: #selector(self.tuneInClicked(_:)), keyEquivalent: "")
                item.representedObject = id
                item.target = self
                item.isEnabled = true
                self.tuneInMenuItem.submenu?.addItem(item)
                NSLog("tuneIn radio station id: \(id), station name: \(name)")
            }

            self.tuneInMenuItem.isHidden = false
            self.addObserver()
        }
    }

    public func addObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name.onNowPlayingRadio, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.NowPlayingRadio {
                DispatchQueue.main.async {
                    NSLog("tuneIn: now playing radio id: \(data.stationId), station name: \(data.name)")

                    for item in self.tuneInMenuItem.submenu!.items {
                        if item.representedObject as! String == data.stationId {
                            item.state = NSControl.StateValue.on
                        } else {
                            item.state = NSControl.StateValue.off
                        }
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.onSourceChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.Source {
                DispatchQueue.main.async {
                    if data.type != "TUNEIN" {
                        NSLog("tuneIn: no longer playing radio")
                        for item in self.tuneInMenuItem.submenu!.items {
                            item.state = NSControl.StateValue.off
                        }
                    }
                }
            }
        }
    }

    public func deviceHasTuneInSource(_ hasSource: Bool) {
        self.tuneInMenuItem.isHidden = !hasSource || !self.hasAnyStations

        if !hasSource && self.hasAnyStations {
            for item in self.tuneInMenuItem.submenu!.items {
                item.state = NSControl.StateValue.off
            }
        }
    }

    @IBAction func tuneInClicked(_ sender: NSMenuItem) {
        NSLog("tuneInClicked")
        let numberOfStations = self.tuneInMenuItem.submenu!.items.count
        let first: Int = self.tuneInMenuItem.submenu!.index(of: sender)
        let sorted = sequence(first: first) {
            let next = ($0+1) % numberOfStations
            return next == first
                ? nil
                : next
        }

        func getTuple(index: Int) -> (String,String) {
            let station = self.tuneInMenuItem.submenu!.item(at: index)!
            let id = station.representedObject as! String
            return (id, station.title)
        }

        let stations = sorted.map(getTuple(index:))
        self.remoteControl.tuneIn(stations: stations)
        NSLog("tuneIn stations: \(stations)")
    }
}
