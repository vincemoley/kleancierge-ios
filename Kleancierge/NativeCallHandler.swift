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
    let ROUTE_CHANGED = "routechanged"
    let REQ_CURR_LOCATION = "requestcurrentlocation"
    let REQUEST_SENT = "requestsent"
    let REQUEST_TIMEOUT = "requesttimeout"
    let RESPONSE_RECEIVED = "responsereceived"
    let APP_VERSION = "appversion"
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody: NSDictionary = message.body as? NSDictionary {
            if let innerBody: NSDictionary = messageBody["body"] as? NSDictionary {
                let type = innerBody["type"] as? String;
                
                if type == APPLOADED {
                    delegate?.appLoaded();
                } else if type == REQ_CURR_LOCATION {
                    delegate?.requestCurrentLocation();
                } else if type == OPEN_CONTACTS {
                    delegate?.requestContactsAccess();
                } else if type == SAVE_LOCAL_NOTIFICATION {
                    let cleaningReminders = innerBody.object(forKey: "reminders") as! NSDictionary
                    
                    let reminders = Reminder.parse(payload: cleaningReminders)
                    
                    reminders.forEach({ reminder in
                        LocalNotification.save(cleaningReminderId: reminder.id,
                                                 notificationDate: reminder.date,
                                                 notificationTitle: reminder.title,
                                                 notificationBody: reminder.body);
                        })
                } else if type == REMOVE_LOCAL_NOTIFICATION {
                    LocalNotification.remove(cleaningReminderId: innerBody["cleaningReminderId"] as! Int)
                } else if type == ROUTE_CHANGED {
                    delegate?.updateCurrentUrl(url: innerBody["path"] as! String)
                } else if type == REQUEST_SENT {
                    delegate?.requestSent(url: innerBody["url"] as! String)
                } else if type == REQUEST_TIMEOUT {
                    delegate?.requestTimeout(url: innerBody["url"] as! String)
                } else if type == RESPONSE_RECEIVED {
                    delegate?.responseReceived()
                } else if type == APP_VERSION {
                    delegate?.appVersion(version: innerBody["version"] as! String)
                } else {
                    print("unable to handle type: " + type!);
                }
            }
        }
    }}
