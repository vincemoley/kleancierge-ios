//
//  LocalNotification.swift
//  Kleancierge
//
//  Created by Vincent Moley on 12/28/17.
//  Copyright © 2017 Vincent Moley. All rights reserved.
//

import UIKit
import UserNotifications

class LocalNotification: NSObject {
    static func save(cleaningReminderId identifier: Int,
                       notificationDate date: Date,
                       notificationTitle title: String,
                       notificationBody body: String){
        remove(cleaningReminderId: identifier)
        create(cleaningReminderId: identifier, notificationDate: date, notificationTitle: title, notificationBody: body)
    }
    
    static func remove(cleaningReminderId identifier: Int){
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: [String(identifier)]);
    }
    
    static private func create(cleaningReminderId identifier: Int,
                       notificationDate date: Date,
                       notificationTitle title: String,
                       notificationBody body: String){
        let content = UNMutableNotificationContent()
        
        content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
        content.sound = UNNotificationSound.default()
        
        let calendar = NSCalendar.current
        let dateInfo = calendar.dateComponents([.month, .day, .year, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        let request = UNNotificationRequest(identifier: String(identifier), content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests(completionHandler: {requests -> () in
            var idFound:Bool = false
            
            for req in requests {
                if req.identifier == String(identifier) {
                    idFound = true
                }
            }
            
            if !idFound {
                center.add(request){(error: Error?) in
                    if let theError = error {
                        print(theError)
                    }
                }
            } else {
                print("Cleaning Reminder already exists")
            }
        })
    }
}
