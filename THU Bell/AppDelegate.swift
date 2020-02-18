//
//  AppDelegate.swift
//  THU Bell
//
//  Created by Lyric Zhao on 2020/2/16.
//  Copyright © 2020 Lyric Zhao. All rights reserved.
//

import Cocoa
import SwiftUI
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var stopRingButton: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var audioPlayer: AVAudioPlayer!
    
    let thuTimeZone = TimeZone(identifier: "Asia/Hong_Kong")
    
    var nextDate: Date!
    var nextWeekDay, nextIndex: Int!
    var timer: Timer!
    var trigger = false
    
    // MARK: Time table
    let times = ["08:00:00", "08:45:00", "08:50:00", "09:35:00", "09:50:00", "10:35:00", "10:40:00", "11:25:00", "11:30:00", "12:15:00", "13:30:00", "14:15:00", "14:20:00", "15:05:00", "15:20:00", "16:05:00", "16:10:00", "16:55:00", "17:05:00", "17:50:00", "17:55:00", "18:40:00", "19:20:00", "20:05:00", "20:10:00", "20:55:00", "21:00:00", "21:45:00"]
    
    @IBOutlet var timeDisplay: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Status menu
        statusItem.menu = menu
        menu.autoenablesItems = false
        if let button = statusItem.button {
            button.title = "📢"
        }
        
        // Load sound
        guard let url = Bundle.main.url(forResource: "sound", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            NSApplication.shared.terminate(self)
        }
        audioPlayer.delegate = self
        
        // Sleep and wake up support
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onWakeNote(note:)), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector:#selector(onSleepNote(note:)), name: NSWorkspace.willSleepNotification, object: nil)
        
        // Initialize time setting
        reset()
    }
    
    // Calculate next time
    func next() {
        nextIndex += 1
        if nextIndex == times.count {
            nextIndex = 0
            if nextWeekDay >= 5 {
                nextDate.addTimeInterval(TimeInterval((8 - nextWeekDay) * 86400))
                nextWeekDay = 1
            } else {
                nextDate.addTimeInterval(86400)
                nextWeekDay += 1
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = thuTimeZone
        dateFormatter.dateFormat = "YYYY-MM-dd"

        let formatter = DateFormatter()
        formatter.timeZone = thuTimeZone
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        nextDate = formatter.date(from: dateFormatter.string(from: nextDate) + " " + times[nextIndex])
    }
    
    // Time up
    @objc func setNextTime() {
        if trigger {
            print("Bell starts ringing.")
            self.audioPlayer.play()
            stopRingButton.isEnabled = true
        }
        
        let formatter = DateFormatter() // Local time formatter
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: nextDate)
        
        print("Set a timer for next time (local time): \(dateString).")
        self.timeDisplay.title = "下次铃声：" + dateString
        
        timer = Timer(fireAt: nextDate, interval: 0, target: self, selector: #selector(setNextTime), userInfo: nil, repeats: false)
        trigger = true
        RunLoop.current.add(timer, forMode: .common)
        next()
    }
    
    // Calculate the weekday
    func getWeekDay(date: Date) -> Int {
        let interval = Int(date.timeIntervalSince1970) + (thuTimeZone?.secondsFromGMT())!
        let days = Int(interval / 86400)
        let weekday = ((days + 4) % 7 + 7) % 7
        return weekday == 0 ? 7 : weekday
    }
    
    // Initialize time setting
    func reset() {
        trigger = false
        stopRingButton.isEnabled = false
        
        nextDate = Date()
        let formatter = DateFormatter()
        formatter.timeZone = thuTimeZone
        formatter.dateFormat = "HH:mm:ss"
        
        let currentTime = "\(formatter.string(from: nextDate))"
        
        nextWeekDay = getWeekDay(date: nextDate)
        
        if currentTime >= times[times.count - 1] || nextWeekDay > 5 { // Late night or weekend
            nextIndex = times.count
        } else {
            for (index, time) in times.enumerated() {
                if time > currentTime {
                    nextIndex = index
                    break
                }
            }
        }
        
        nextIndex -= 1
        next()
        setNextTime()
    }
    
    // Wake up and reset
    @objc func onWakeNote(note: NSNotification) {
        print("System wakes up, reset the timer.")
        reset()
    }
    
    // Sleep and cancel the timer
    @objc func onSleepNote(note: NSNotification) {
        print("System sleeps, cancel the timer.")
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    // Quit
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    // Skip current ring
    @IBAction func stopRing(_ sender: Any) {
        guard audioPlayer.isPlaying else {
            print("Bell is not ringing.")
            return
        }
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        stopRingButton.isEnabled = false
    }
    
    // When the bell finishes playing, this function will be evoked
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Bell finished.")
        stopRingButton.isEnabled = false
    }
}

