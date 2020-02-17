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
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var menu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var audioPlayer: AVAudioPlayer!
    
    var nextDate: Date!
    var nextWeekDay, nextIndex: Int!
    var timer: Timer!
    var trigger = false
    
    let times = ["08:00:00", "08:45:00", "08:50:00", "09:35:00", "09:50:00", "10:35:00", "10:40:00", "11:25:00", "11:30:00", "12:15:00", "13:30:00", "14:15:00", "14:20:00", "15:05:00", "15:20:00", "16:05:00", "16:10:00", "16:55:00", "17:05:00", "17:50:00", "17:55:00", "18:40:00", "19:20:00", "20:05:00", "20:10:00", "20:55:00", "21:00:00", "21:45:00"]
    
    @IBOutlet var timeDisplay: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = menu
        if let button = statusItem.button {
            button.title = "📢"
        }
        guard let url = Bundle.main.url(forResource: "sound", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            NSApplication.shared.terminate(self)
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onWakeNote(note:)), name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self, selector:#selector(onSleepNote(note:)), name: NSWorkspace.willSleepNotification, object: nil)
        
        reset()
    }
    
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
        dateFormatter.dateFormat = "YYYY-MM-dd"
            
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        nextDate = formatter.date(from: dateFormatter.string(from: nextDate) + " " + times[nextIndex])
    }
    
    @objc func setNextTime() {
        if trigger {
            self.audioPlayer.play()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: nextDate)
        
        timer = Timer(fireAt: nextDate, interval: 0, target: self, selector: #selector(setNextTime), userInfo: nil, repeats: false)
        trigger = true
        RunLoop.current.add(timer, forMode: .common)
        next()
        
        print("Set a timer for next time: \(dateString).")
        self.timeDisplay.title = "下次铃声：" + dateString
    }

    func getWeekDay(date: Date) -> Int {
        let interval = Int(date.timeIntervalSince1970) + NSTimeZone.local.secondsFromGMT()
        let days = Int(interval / 86400)
        let weekday = ((days + 4) % 7 + 7) % 7
        return weekday == 0 ? 7 : weekday
    }
    
    func reset() {
        trigger = false
        
        nextDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let currentTime = "\(formatter.string(from: nextDate))"
        
        nextWeekDay = getWeekDay(date: nextDate)
        
        if currentTime >= times[times.count - 1] || nextWeekDay > 5 { // Late night or weekend
            nextIndex = times.count
        } else {
            if currentTime < times[0] {
                nextIndex = 0
            } else {
                for (index, time) in times.enumerated() {
                    if currentTime >= time {
                        nextIndex = index + 1
                    } else {
                        break
                    }
                }
            }
        }
        
        nextIndex -= 1
        next()
        setNextTime()
    }
    
    @objc func onWakeNote(note: NSNotification) {
        print("System wakes up, reset the timer.")
        reset()
    }
    
    @objc func onSleepNote(note: NSNotification) {
        print("System sleeps, cancel the timer.")
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}

