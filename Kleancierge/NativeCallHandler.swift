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
    let CREATE_LOCAL_NOTIFICATION = "createlocalnotfication"
    let UPDATE_LOCAL_NOTIFICATION = "updatelocalnotfication"
    let REMOVE_LOCAL_NOTIFICATION = "removelocalnotification"
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody: NSDictionary = message.body as? NSDictionary {
            if let innerBody: NSDictionary = messageBody["body"] as? NSDictionary {
                //print(innerBody);
                
                let type = innerBody["type"] as? String;
                
                if type == APPLOADED {
                    delegate?.appLoaded();
                } else if type == OPEN_CONTACTS {
                    delegate?.requestContactsAccess();
                } else if type == CREATE_LOCAL_NOTIFICATION || type == UPDATE_LOCAL_NOTIFICATION {
                    let cleaningReminderId = innerBody["cleaningReminderId"] as! Int;
                    let dateStr = innerBody["date"] as! String;
                    let title = innerBody["title"] as! String;
                    let body = innerBody["body"] as! String;
                    
                    let df = DateFormatter()
                    
                    df.dateFormat = "YYYY-MM-dd HH:mm"
                    
                    if type == CREATE_LOCAL_NOTIFICATION {
                        LocalNotification.create(cleaningReminderId: cleaningReminderId,
                                                 notificationDate: df.date(from: dateStr)!,
                                                 notificationTitle: title,
                                                 notificationBody: body);
                    } else {
                        LocalNotification.update(cleaningReminderId: cleaningReminderId,
                                                 notificationDate: df.date(from: dateStr)!,
                                                 notificationTitle: title,
                                                 notificationBody: body);
                    }
                } else if type == REMOVE_LOCAL_NOTIFICATION {
                    let cleaningReminderIds = innerBody["cleaningReminderId"] as! NSMutableArray;
                    
                    for cri in cleaningReminderIds {
                        LocalNotification.remove(cleaningReminderId: cri as! Int)
                    }
                } else {
                    print("unable to handle type: " + type!);
                }
            }
        }
    }}
