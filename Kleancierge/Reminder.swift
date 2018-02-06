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
    var dateOfCleaning: Date
    var qty = 0
    var units = ""
    var body = ""
    let title = "Cleaning Appointment Reminder"
    
    init(reminderId id: Int, dateTimeOfReminder reminderDate: Date, dateTimeOfCleaning dateOfCleaning: Date, qtyOfUnits qty: Int, unitsUntilCleaning units: String) {
        self.id = id
        self.date = reminderDate
        self.dateOfCleaning = dateOfCleaning
        self.qty = qty
        self.units = units
        
        let df = DateFormatter()
        
        df.dateFormat = "MM/dd/YYYY @ hh:mm a"
        
        self.body = "Your cleaning appointment for \(df.string(from: self.dateOfCleaning)) is in \(qty) \(units)"
    }
    
    public static func parse(payload cleaningReminders: NSDictionary) -> [Reminder]{
        var reminders = [Reminder]()
        
        cleaningReminders.allKeys.forEach({ key in
            let value = cleaningReminders.object(forKey: key) as! NSDictionary
            let cleaningReminderId = Int("\(key)")!
            let reminderDateStr = value["date"] as! String;
            let dateOfCleaningStr = value["cleaningDateTime"] as! String;
            let qty = value["qty"] as! String;
            let units = value["units"] as! String;
            
            let df = DateFormatter()
            
            df.dateFormat = "YYYY-MM-dd HH:mm"
            
            reminders.append(Reminder(reminderId: cleaningReminderId,
                                      dateTimeOfReminder: df.date(from: reminderDateStr)!,
                                      dateTimeOfCleaning: df.date(from: dateOfCleaningStr)!,
                                      qtyOfUnits: Int(qty)!,
                                      unitsUntilCleaning: units))
        })
        
        return reminders
    }
}
