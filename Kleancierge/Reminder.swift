//
//  Reminder.swift
//  Kleancierge
//
//  Created by Vincent Moley on 1/18/18.
//  Copyright © 2018 Vincent Moley. All rights reserved.
//

import UIKit

class Reminder: NSObject {
    var id = 0
    var date: Date
    var qty = 0
    var units = ""
    var body = ""
    let title = "Cleaning Appointment Reminder"
    
    init(reminderId id: Int, dateOfReminder date: Date, qtyOfUnits qty: Int, unitsUntilCleaning units: String) {
        self.id = id
        self.date = date
        self.qty = qty
        self.units = units
        self.body = "Your cleaning appointment is in \(qty) \(units)"
    }
    
    public static func parse(payload cleaningReminders: NSDictionary) -> [Reminder]{
        var reminders = [Reminder]()
        
        cleaningReminders.allKeys.forEach({ key in
            let value = cleaningReminders.object(forKey: key) as! NSDictionary
            let cleaningReminderId = Int("\(key)")!
            let dateStr = value["date"] as! String;
            let qty = value["qty"] as! String;
            let units = value["units"] as! String;
            
            let df = DateFormatter()
            
            df.dateFormat = "YYYY-MM-dd HH:mm"
            
            reminders.append(Reminder(reminderId: cleaningReminderId,
                                      dateOfReminder: df.date(from: dateStr)!,
                                      qtyOfUnits: Int(qty)!,
                                      unitsUntilCleaning: units))
        })
        
        return reminders
    }
}
