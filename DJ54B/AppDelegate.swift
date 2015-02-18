//
//  AppDelegate.swift
//  DJ54B
//
//  Created by Jamie White on 14/02/2015.
//  Copyright (c) 2015 Jamie White. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let notificationCenter: NSNotificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var songItem: NSMenuItem!
    @IBOutlet weak var artistItem: NSMenuItem!
    @IBOutlet weak var volumeItem: NSMenuItem!
    @IBOutlet weak var playPauseItem: NSMenuItem!

    var info:NSDictionary?
    var track: NSDictionary? { return info?["track"] as? NSDictionary }
    var songID: String? { return track?["id"] as? String }
    var songLabel: String? { return track?["name"] as? String }
    var artistLabel: String? { return track?["artist"] as? String }
    var volumeLabel: Int? { return info?["volume"] as? Int }
    var state: String? { return info?["state"] as? String }
    var isPlaying: Bool { return state == "playing" }

    var timer: NSTimer?
    var busy: Bool = false

    func applicationDidFinishLaunching(notification: NSNotification) {
        statusItem.title = "DJ"
        statusItem.highlightMode = true
        statusItem.menu = menu

        refresh()
        startTimer()
        registerForNotifications()
    }

    func refresh() {
        if !busy {
            run("info")
        }
    }

    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(
            5,
            target: self,
            selector: Selector("refresh"),
            userInfo: nil,
            repeats: true
        )
    }

    func registerForNotifications() {
        notificationCenter.addObserver(
            self,
            selector: Selector("sleep"),
            name: NSWorkspaceWillSleepNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: Selector("wake"),
            name: NSWorkspaceDidWakeNotification,
            object: nil
        )
    }

    @IBAction func playOrPause(sender: AnyObject) {
        if isPlaying {
            run("pause")
        } else {
            run("play")
        }
    }

    @IBAction func next(sender: AnyObject) {
        run("next")
    }

    @IBAction func up(sender: AnyObject) {
        run("up")
    }

    @IBAction func down(sender: AnyObject) {
        run("down")
    }

    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(nil)
    }

    @IBAction func openInSpotify(sender: AnyObject) {
        if let songID = self.songID {
            if let url = NSURL(string: songID) {
                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
    }

    func sleep() {
        timer?.invalidate()
        timer = nil
    }

    func wake() {
        startTimer()
    }

    private func run(command: String) {
        busy = true

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let maybeInfo = self.fetch("http://lorne.withassociates.com:9292/\(command)")

            self.busy = false

            if let info = maybeInfo {
                self.info = info
                self.updateUI()
            }
        }
    }

    private func updateUI() {
        dispatch_async(dispatch_get_main_queue()) {
            self.songItem.title = self.songLabel!
            self.artistItem.title = self.artistLabel!
            self.volumeItem.title = "Volume: \(self.volumeLabel!)"

            if self.isPlaying {
                self.playPauseItem.title = "Pause"
            } else {
                self.playPauseItem.title = "Play"
            }
        }
    }

    private func fetch(url: String) -> NSDictionary? {
        if let json = getJSON(url) {
            return parseJSON(json)
        } else {
            return nil
        }
    }

    private func getJSON(urlToTry: String) -> NSData? {
        if let url = NSURL(string: urlToTry) {
            return NSData(contentsOfURL: url)
        } else {
            return nil
        }
    }

    private func parseJSON(inputData: NSData) -> NSDictionary? {
        var error: NSError?

        return NSJSONSerialization.JSONObjectWithData(
            inputData,
            options: NSJSONReadingOptions.MutableContainers,
            error: &error
        ) as? NSDictionary
    }
}