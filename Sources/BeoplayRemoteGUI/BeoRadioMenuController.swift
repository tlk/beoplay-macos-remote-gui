//
//  BeoRadioMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 15/04/2026.
//

import Cocoa
import RemoteCore

public class BeoRadioMenuController {
    private struct BeoRadioSelection {
        let sourceId: String
        let stationId: String
        let stationName: String
    }

    private let remoteControl: RemoteControl
    private let beoRadioMenuItem: NSMenuItem

    public init(remoteControl: RemoteControl, beoRadioMenuItem: NSMenuItem) {
        self.remoteControl = remoteControl
        self.beoRadioMenuItem = beoRadioMenuItem
    }

    public func onNowPlayingRadio(_ data: RemoteCore.NowPlayingRadio) {
        NSLog("now playing radio, station id: \(data.stationId), station name: \(data.name)")

        for item in self.beoRadioMenuItem.submenu!.items {
            item.state = selection(from: item.representedObject)?.stationId == data.stationId
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

    private func selection(from representedObject: Any?) -> BeoRadioSelection? {
        if let selection = representedObject as? BeoRadioSelection {
            return selection
        }

        if let stationId = representedObject as? String {
            return BeoRadioSelection(sourceId: "", stationId: stationId, stationName: stationId)
        }

        return nil
    }

    private func fillMenu(_ favorites: [BeoRadioSelection]) {
        guard favorites.count > 0 else {
            return
        }

        DispatchQueue.main.async {
            self.beoRadioMenuItem.isHidden = false

            for station in favorites {
                let item = NSMenuItem(title: station.stationName, action: #selector(self.beoRadioClicked(_:)), keyEquivalent: "")
                item.representedObject = station
                item.target = self
                item.isEnabled = true
                self.beoRadioMenuItem.submenu?.addItem(item)
                NSLog("beoradio station id: \(station.stationId), station name: \(station.stationName)")
            }
        }
    }

    public func enable(sourceId: String) {
        NSLog("load beoradio favorites")

        let defaultKeys = UserDefaults.standard
        if  let order = defaultKeys.array(forKey: "beoradio.order"),
            let stations = defaultKeys.dictionary(forKey: "beoradio.stations"),
            order.count == stations.count {

            var favorites = [BeoRadioSelection]()
            for id in order {
                if let sid = id as? String, let name = stations[sid] as? String {
                    favorites.append(BeoRadioSelection(sourceId: sourceId, stationId: sid, stationName: name))
                }
            }

            if favorites.count > 0 {
                NSLog("beoradio favorites from user defaults")
                fillMenu(favorites)
                return
            }
        }

        NSLog("beoradio favorites from device")
        self.remoteControl.getRadioFavorites { (favorites: [(String,String)]) in
            var stations = favorites.map { station in
                BeoRadioSelection(sourceId: sourceId, stationId: station.0, stationName: self.scrub(station.1))
            }

            if let customNames = UserDefaults.standard.dictionary(forKey: "beoradio.stations") {
                stations = stations.map { station in
                    if let customName = customNames[station.stationId] as? String {
                        return BeoRadioSelection(sourceId: station.sourceId, stationId: station.stationId, stationName: customName)
                    } else {
                        return station
                    }
                }
            }

            self.fillMenu(stations)
        }
    }

    public func disable() {
        DispatchQueue.main.async {
            self.beoRadioMenuItem.isHidden = true
            self.beoRadioMenuItem.submenu?.removeAllItems()
        }
    }

    public func clear() {
        for item in self.beoRadioMenuItem.submenu!.items {
            item.state = NSControl.StateValue.off
        }
    }

    @IBAction func beoRadioClicked(_ sender: NSMenuItem) {
        NSLog("beoRadioClicked")

        guard let selection = selection(from: sender.representedObject) else {
            NSLog("beoRadioClicked: missing selection data")
            return
        }

        self.remoteControl.setSourceAndContent(sourceId: selection.sourceId, contentId: selection.stationId)
        NSLog("beoradio selection: source id \(selection.sourceId), station id \(selection.stationId), station name \(selection.stationName)")
    }
}
