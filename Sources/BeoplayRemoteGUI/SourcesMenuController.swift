//
//  SourcesMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 01/12/2019.
//

import Cocoa
import RemoteCore

public class SourcesMenuController {
    private let remoteControl: RemoteControl
    private let tuneInMenuController: TuneInMenuController?
    private let sourcesMenuItem: NSMenuItem
    private let separatorMenuItem: NSMenuItem
    private var hideTypes: [String] = []
    private var lastKnownSourceId: String? = nil

    public init(remoteControl: RemoteControl, tuneInMenuController: TuneInMenuController?, sourcesMenuItem: NSMenuItem, separatorMenuItem: NSMenuItem) {
        self.remoteControl = remoteControl
        self.tuneInMenuController = tuneInMenuController
        self.sourcesMenuItem = sourcesMenuItem
        self.separatorMenuItem = separatorMenuItem

        if let tmp = UserDefaults.standard.array(forKey: "sources.hideTypes") {
            hideTypes = tmp.map { ($0 as! String).lowercased() }
        }
    }

    public func addObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name.onSourceChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            guard let data = notification.userInfo?["data"] as? RemoteCore.Source else {
                return
            }

            DispatchQueue.main.async {
                NSLog("source changed: \(data.id)")

                var sourceId = data.id

                let musicAliases = ["DEEZER", "QPLAY"]
                if musicAliases.contains(data.type) {
                    sourceId = data.id
                        .replacingOccurrences(of: "deezer:", with: "music:")
                        .replacingOccurrences(of: "qplay:", with: "music:")
                    NSLog("source id modified to match with enabled sources: \(data.id) -> \(sourceId)")
                }

                self.lastKnownSourceId = sourceId

                for item in self.sourcesMenuItem.submenu!.items[2...] {
                    if let x = item.representedObject as? String, x == sourceId {
                        item.state = NSControl.StateValue.on
                    } else {
                        item.state = NSControl.StateValue.off
                    }
                }

                if data.type != "TUNEIN" {
                    self.tuneInMenuController?.clear()
                }
            }
        }
    }

    public func disable() {
        DispatchQueue.main.async {
            self.sourcesMenuItem.isHidden = true

            if let existingItems = self.sourcesMenuItem.submenu?.items[2...] {
                for item in existingItems {
                    self.sourcesMenuItem.submenu?.removeItem(item)
                }
            }

            self.lastKnownSourceId = nil
            self.tuneInMenuController?.disable()
        }
    }

    public func enable() {
        NSLog("load sources")

        self.remoteControl.getEnabledSources { (sources: [BeoplaySource]) in
            DispatchQueue.main.async {
                self.sourcesMenuItem.isHidden = false

                var hasTuneInSource = false

                for source in sources {
                    if self.hideTypes.contains(source.sourceType.lowercased()) {
                        continue
                    }

                    if source.sourceType == "TUNEIN" {
                        hasTuneInSource = true
                    }

                    let name = source.borrowed
                        ? "\(source.friendlyName) (\(source.productFriendlyName))"
                        : source.friendlyName

                    let item = NSMenuItem(title: name, action: #selector(self.setSource(_:)), keyEquivalent: "")
                    item.representedObject = source.id
                    item.target = self
                    item.isEnabled = true
                    item.state = source.id == self.lastKnownSourceId
                        ? NSControl.StateValue.on
                        : NSControl.StateValue.off
                    self.sourcesMenuItem.submenu?.addItem(item)
                    NSLog("source id: \(source.id), source name: \(name)")
                }

                if hasTuneInSource {
                    self.tuneInMenuController?.enable()
                } else {
                    self.tuneInMenuController?.disable()
                }
            }
        }
    }

    @IBAction func setSource(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String {
            NSLog("setSource: \(id)")
            self.remoteControl.setSource(id: id)
        }
    }
}
