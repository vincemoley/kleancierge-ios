//
//  NativeCallHandler.swift
//  Kleancierge
//
//  Created by Vincent Moley on 10/17/17.
//  Copyright © 2017 Vincent Moley. All rights reserved.
//

import UIKit
import WebKit

class NativeCallHandler: NSObject, WKScriptMessageHandler {
    //https://medium.com/@tonespy/communicating-between-angular-javascript-in-wkwebview-and-native-code-368e6941d7f5#.4rbzatuys
    
    var delegate: NativeCallHandlerDelegate?
    
    let APPLOADED: String = "apploaded"
    let OPEN_CONTACTS: String = "opencontacts"
    let SAVE_LOCAL_NOTIFICATION = "savelocalnotfication"
    let REMOVE_LOCAL_NOTIFICATION = "removelocalnotification"
    let CLEAR_SESSION = "clearsession"
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody: NSDictionary = message.body as? NSDictionary {
            if let innerBody: NSDictionary = messageBody["body"] as? NSDictionary {
                print(innerBody);
                
                let type = innerBody["type"] as? String;
                
                if type == APPLOADED {
                    delegate?.appLoaded();
                } else if type == OPEN_CONTACTS {
                    delegate?.requestContactsAccess();
                } else if type == SAVE_LOCAL_NOTIFICATION {
                    let cleaningReminders = innerBody.object(forKey: "reminders") as! NSDictionary
                    let title = "Cleaning Appointment Reminder"
                    
                    cleaningReminders.allKeys.forEach({ key in
                        let value = cleaningReminders.object(forKey: key) as! NSDictionary
                        let cleaningReminderId = Int("\(key)")
                        let dateStr = value["date"] as! String;
                        let qty = value["qty"] as! Int;
                        let units = value["units"] as! String;
                        let body = "Your cleaning appointment is in \(qty) \(units)"
                        
                        let df = DateFormatter()
                        
                        df.dateFormat = "YYYY-MM-dd HH:mm"
                        
                        LocalNotification.save(cleaningReminderId: cleaningReminderId!,
                                                 notificationDate: df.date(from: dateStr)!,
                                                 notificationTitle: title,
                                                 notificationBody: body);
                        })
                } else if type == REMOVE_LOCAL_NOTIFICATION {
                    LocalNotification.remove(cleaningReminderId: innerBody["cleaningReminderId"] as! Int)
                } else if type == CLEAR_SESSION {
                    delegate?.clearSession()
                } else {
                    print("unable to handle type: " + type!);
                }
            }
        }
    }}
