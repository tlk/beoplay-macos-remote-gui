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

    public init(remoteControl: RemoteControl, tuneInMenuItem: NSMenuItem) {
        self.remoteControl = remoteControl
        self.tuneInMenuItem = tuneInMenuItem
    }

    public func onNowPlayingRadio(_ data: RemoteCore.NowPlayingRadio) {
        NSLog("now playing radio, tuneIn station id: \(data.stationId), station name: \(data.name)")

        for item in self.tuneInMenuItem.submenu!.items {
            item.state = item.representedObject as? String == data.stationId
                ? NSControl.StateValue.on
                : NSControl.StateValue.off
        }
    }

    // Example: "96.5 | DR P4 København (Euro Hits)" -> "DR P4 København"
    private func scrub(_ s: String) -> String {
        var result = s
        if let range = s.range(of: #"^.* \| "#, options: .regularExpression) {
            result.removeSubrange(range)
        }

        if let range = result.range(of: #" \(.*\)$"#, options: .regularExpression) {
            result.removeSubrange(range)
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }

    private func fillMenu(_ favorites: [(String,String)]) {
        guard favorites.count > 0 else {
            return
        }

        DispatchQueue.main.async {
            self.tuneInMenuItem.isHidden = false

            for station in favorites {
                let item = NSMenuItem(title: station.1, action: #selector(self.tuneInClicked(_:)), keyEquivalent: "")
                item.representedObject = station.0
                item.target = self
                item.isEnabled = true
                self.tuneInMenuItem.submenu?.addItem(item)
                NSLog("tuneIn station id: \(station.0), station name: \(station.1)")
            }
        }
    }

    public func enable() {
        NSLog("load tuneIn favorites")

        if  let order = UserDefaults.standard.array(forKey: "tuneIn.order"),
            let stations = UserDefaults.standard.dictionary(forKey: "tuneIn.stations"),
            order.count == stations.count {

            var favorites = [(String,String)]()
            for id in order {
                if let sid = id as? String, let name = stations[sid] as? String {
                    favorites.append((sid, name))
                }
            }

            if favorites.count > 0 {
                NSLog("tuneIn favorites from user defaults")
                fillMenu(favorites)
                return
            }
        }

        NSLog("tuneIn favorites from device")
        self.remoteControl.getTuneInFavorites { (favorites: [(String,String)]) in
            var stations = favorites.map { f in (f.0, self.scrub(f.1)) }

            if let customNames = UserDefaults.standard.dictionary(forKey: "tuneIn.stations") {
                stations = stations.map { f in
                    if let customName = customNames[f.0] as? String {
                        return (f.0, customName)
                    } else {
                        return f
                    }
                }
            }

            self.fillMenu(stations)
        }
    }

    public func disable() {
        DispatchQueue.main.async {
            self.tuneInMenuItem.isHidden = true
            self.tuneInMenuItem.submenu?.removeAllItems()
        }
    }

    public func clear() {
        for item in self.tuneInMenuItem.submenu!.items {
            item.state = NSControl.StateValue.off
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
