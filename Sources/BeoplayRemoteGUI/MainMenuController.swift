//
//  StatusMenuController.swift
//  BeoplayRemoteGUI
//
//  Created by Thomas L. Kjeldsen on 03/06/2019.
//

import Cocoa
import RemoteCore

class MainMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var volumeLevelMenuItem: NSMenuItem!
    @IBOutlet weak var volumeLevelView: VolumeLevelView!
    @IBOutlet weak var volumeLevelSlider: NSSlider!

    @IBOutlet weak var deviceSeparatorMenuItem: NSMenuItem!
    @IBOutlet weak var sourcesMenuItem: NSMenuItem!
    @IBOutlet weak var tuneInMenuItem: NSMenuItem!
    @IBOutlet weak var separatorMenuItem: NSMenuItem!

    private let menuBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let remoteControl = RemoteControl()
    private let deviceController = DeviceController()
    private var volumeLevelViewController: VolumeLevelViewController?
    private var hotkeysController: HotkeysController?
    private var sourcesMenuController: SourcesMenuController?
    private var tuneInMenuController: TuneInMenuController?


    override func awakeFromNib() {
        menuBar.button?.title = UserDefaults.standard.string(forKey: "app.title") ?? "BeoplayRemote"
        menuBar.menu = statusMenu

        if UserDefaults.standard.bool(forKey: "hotkeys.enabled") {
            hotkeysController = HotkeysController(remoteControl: remoteControl)
            hotkeysController?.setup()
        }

        if UserDefaults.standard.bool(forKey: "tuneIn.enabled") {
            tuneInMenuController = TuneInMenuController(remoteControl: remoteControl, tuneInMenuItem: tuneInMenuItem)
            tuneInMenuController?.setup()
        }

        volumeLevelViewController = VolumeLevelViewController(
            remoteControl: remoteControl,
            volumeLevelMenuItem: volumeLevelMenuItem,
            volumeLevelView: volumeLevelView,
            volumeLevelSlider: volumeLevelSlider)

        sourcesMenuController = SourcesMenuController(
            remoteControl: remoteControl,
            tuneInMenuController: tuneInMenuController,
            sourcesMenuItem: sourcesMenuItem,
            separatorMenuItem: separatorMenuItem)

        deviceController.menuController = DeviceMenuController(
            remoteControl: remoteControl,
            statusMenu: statusMenu,
            deviceSeparatorMenuItem: deviceSeparatorMenuItem,
            volumeLevelViewController: volumeLevelViewController!,
            sourcesMenuController: sourcesMenuController!)
    
        remoteControl.startDiscovery(delegate: deviceController)
    }

    @IBAction func sliderMoved(_ sender: NSSlider) {
        self.volumeLevelViewController?.sliderMoved(sender)
    }
    
    @IBAction func joinClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.join()
            NSLog("join")
        }
    }

    @IBAction func leaveClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.leave()
            NSLog("leave")
        }
    }

    @IBAction func playClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.play()
            NSLog("play")
        }
    }

    @IBAction func pauseClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.pause()
            NSLog("pause")
        }
    }

    @IBAction func forwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.forward()
            NSLog("forward")
        }
    }

    @IBAction func backwardClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteControl.backward()
            NSLog("backward")
        }
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
        NSLog("quit")
    }
}
