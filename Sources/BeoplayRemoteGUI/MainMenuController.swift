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
    private var deviceMenuController: DeviceMenuController?
    private var volumeLevelViewController: VolumeLevelViewController?
    private var hotkeysController: HotkeysController?
    private var sourcesMenuController: SourcesMenuController?
    private var tuneInMenuController: TuneInMenuController?

    override func awakeFromNib() {
        menuBar.button?.title = UserDefaults.standard.string(forKey: "app.title") ?? "BeoplayRemote"
        menuBar.menu = statusMenu

        if UserDefaults.standard.bool(forKey: "hotkeys.enabled") {
            hotkeysController = HotkeysController(remoteControl: remoteControl)
        }

        if UserDefaults.standard.bool(forKey: "tuneIn.enabled") {
            tuneInMenuController = TuneInMenuController(remoteControl: remoteControl, tuneInMenuItem: tuneInMenuItem)
            tuneInMenuController?.enable()
            separatorMenuItem.isHidden = false
        }

        volumeLevelViewController = VolumeLevelViewController(
            remoteControl: remoteControl,
            volumeLevelMenuItem: volumeLevelMenuItem,
            volumeLevelView: volumeLevelView,
            volumeLevelSlider: volumeLevelSlider)

        if UserDefaults.standard.bool(forKey: "sources.enabled") {
            sourcesMenuController = SourcesMenuController(
                remoteControl: remoteControl,
                tuneInMenuController: tuneInMenuController,
                sourcesMenuItem: sourcesMenuItem,
                separatorMenuItem: separatorMenuItem)
            sourcesMenuController?.enable()
            separatorMenuItem.isHidden = false
        }

        deviceMenuController = DeviceMenuController(
            remoteControl: remoteControl,
            statusMenu: statusMenu,
            volumeLevelViewController: volumeLevelViewController!,
            deviceSeparatorMenuItem: deviceSeparatorMenuItem,
            sourcesMenuController: sourcesMenuController)

        volumeLevelViewController?.addObserver()
        sourcesMenuController?.addObserver()
        deviceMenuController?.addObserver()

        let deviceBrowserDelegate = DeviceBrowserDelegate(deviceMenuController: deviceMenuController!)
        remoteControl.startDiscovery(delegate: deviceBrowserDelegate)
    }

    @IBAction func sliderMoved(_ sender: NSSlider) {
        // Do this on the main thread for maximum scrolling smoothness
        self.volumeLevelViewController?.sliderMoved(sender)
    }
    
    @IBAction func joinClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("joinClicked")
            self.remoteControl.join()
        }
    }

    @IBAction func leaveClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("leaveClicked")
            self.remoteControl.leave()
        }
    }

    @IBAction func playClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("playClicked")
            self.remoteControl.play()
        }
    }

    @IBAction func pauseClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("pauseClicked")
            self.remoteControl.pause()
        }
    }

    @IBAction func nextClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("nextClicked")
            self.remoteControl.next()
        }
    }

    @IBAction func backClicked(_ sender: NSMenuItem) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSLog("backClicked")
            self.remoteControl.back()
        }
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSLog("quitClicked")
        NSApplication.shared.terminate(self)
    }
}
