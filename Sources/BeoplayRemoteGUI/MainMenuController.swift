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

    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBOutlet weak var pauseMenuItem: NSMenuItem!
    @IBOutlet weak var nextMenuItem: NSMenuItem!
    @IBOutlet weak var backMenuItem: NSMenuItem!

    private let menuBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let remoteControl = RemoteControl()
    private let browser = NetServiceBrowser()

    private var browserDelegate: DeviceBrowserDelegate?
    private var deviceMenuController: DeviceMenuController?
    private var volumeLevelViewController: VolumeLevelViewController?
    private var hotkeysController: HotkeysController?
    private var sourcesMenuController: SourcesMenuController?
    private var tuneInMenuController: TuneInMenuController?

    override func awakeFromNib() {
        UserDefaults.standard.register(defaults: [
            "app.title": "BeoplayRemote",
            "tuneIn.enabled": true,
            "hotkeys.enabled": true
        ])

        menuBar.button?.title = UserDefaults.standard.string(forKey: "app.title")!
        menuBar.menu = statusMenu

        if UserDefaults.standard.bool(forKey: "tuneIn.enabled") {
            tuneInMenuController = TuneInMenuController(remoteControl: remoteControl, tuneInMenuItem: tuneInMenuItem)
        }

        volumeLevelViewController = VolumeLevelViewController(
            remoteControl: remoteControl,
            volumeLevelMenuItem: volumeLevelMenuItem,
            volumeLevelView: volumeLevelView,
            volumeLevelSlider: volumeLevelSlider)

        sourcesMenuController = SourcesMenuController(
            remoteControl: remoteControl,
            tuneInMenuController: tuneInMenuController,
            sourcesMenuItem: sourcesMenuItem)

        deviceMenuController = DeviceMenuController(
            remoteControl: remoteControl,
            statusMenu: statusMenu,
            mainMenuController: self,
            volumeLevelViewController: volumeLevelViewController!,
            deviceSeparatorMenuItem: deviceSeparatorMenuItem,
            sourcesMenuController: sourcesMenuController)

        if UserDefaults.standard.bool(forKey: "hotkeys.enabled") {
            hotkeysController = HotkeysController(
                remoteControl: remoteControl,
                deviceMenuController: deviceMenuController!,
                sourcesMenuController: sourcesMenuController!)

            statusMenu.delegate = hotkeysController
            hotkeysController?.enable()
        }

        addObservers()

        browserDelegate = DeviceBrowserDelegate(deviceMenuController: deviceMenuController!)
        browser.delegate = browserDelegate
        browser.schedule(in: .main, forMode: .default)
        browser.searchForServices(ofType: "_beoremote._tcp.", inDomain: "local.")

        // Watchdog: handle sporadic resolver issues, refs #29
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.deviceMenuController?.resolveDevices()
            }
       }
    }

    func addObservers() {
        NotificationCenter.default.addObserver(forName: Notification.Name.onProgress, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.Progress {
                DispatchQueue.main.async {
                    self.onProgress(data)
                    self.hotkeysController?.onProgress(data)
                }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.onVolumeChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.Volume {
                DispatchQueue.main.async {
                    self.volumeLevelViewController?.onVolumeChange(data)
                    self.hotkeysController?.onVolumeChange(data)
                }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.onSourceChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.Source {
                DispatchQueue.main.async { self.sourcesMenuController?.onSourceChange(data) }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.onConnectionChange, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? NotificationBridge.DataConnectionNotification {
                DispatchQueue.main.async { self.deviceMenuController?.onConnectionChange(data) }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.onNowPlayingRadio, object: nil, queue: nil) { (notification: Notification) -> Void in
            if let data = notification.userInfo?["data"] as? RemoteCore.NowPlayingRadio {
                DispatchQueue.main.async { self.tuneInMenuController?.onNowPlayingRadio(data) }
            }
        }
    }

    func onProgress(_ data: RemoteCore.Progress) {
        if data.state == RemoteCore.DeviceState.play {
            self.playMenuItem.isHidden = true
            self.pauseMenuItem.isHidden = false
        } else {
            self.playMenuItem.isHidden = false
            self.pauseMenuItem.isHidden = true
        }
    }

    func enableControls() {
        playMenuItem.isEnabled = true
        pauseMenuItem.isEnabled = true
        nextMenuItem.isEnabled = true
        backMenuItem.isEnabled = true
    }

    func disableControls() {
        playMenuItem.isEnabled = false
        pauseMenuItem.isEnabled = false
        nextMenuItem.isEnabled = false
        backMenuItem.isEnabled = false

        self.playMenuItem.isHidden = false
        self.pauseMenuItem.isHidden = true
    }

    func open() {
        // Is there another way to do this without triggering the hide/show animation?
        self.menuBar.button?.performClick(self)
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
