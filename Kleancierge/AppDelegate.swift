//
//  AppDelegate.swift
//  Kleancierge
//
//  Created by Vincent Moley on 10/17/17.
//  Copyright © 2017 Vincent Moley. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0;
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL!
            
            if url.absoluteString.starts(with: "https://www.kleancierge.com") {
                let webView = self.window?.rootViewController as! WebViewController
                
                var urlWithParam = url.path;
                
                if url.query != nil {
                    urlWithParam += "?" + url.query!;
                }
                
                webView.redirectFromWebsite(url: urlWithParam)
            }
        }
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if self.window?.rootViewController is WebViewController {
            let webView = self.window?.rootViewController as! WebViewController
            
            webView.determineIfReloadNeeded();
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerForRemoteNotification() {
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current();
            
            center.delegate = self;
            
            center.getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .denied,.notDetermined:
                    center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                        if error == nil {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications();
                            }
                        }
                    }
                case .authorized:
                    break;
                }
            });
        }
        else if !UIApplication.shared.isRegisteredForRemoteNotifications {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil));
            UIApplication.shared.registerForRemoteNotifications();
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
        print("Push notification received: \(data)"); // debugging
        // received for a newly scheduled cleaning
        let cleaningReminders = data[AnyHashable("reminders")] as? NSDictionary
        // received when a cleaning has been canceled
        let cleaningReminderIds = data[AnyHashable("reminderIds")] as? [Int]
        
        if cleaningReminders != nil {
            let reminders = Reminder.parse(payload: cleaningReminders!)
            
            reminders.forEach({ reminder in
                LocalNotification.save(cleaningReminderId: reminder.id,
                                       notificationDate: reminder.date,
                                       notificationTitle: reminder.title,
                                       notificationBody: reminder.body);
            })
        } else if cleaningReminderIds != nil {
            cleaningReminderIds!.forEach({ id in
                LocalNotification.remove(cleaningReminderId: id)
            })
        }
    }
    
    private func application(_ application: UIApplication, didRegister notificationSettings: UNNotificationSettings) {
        if notificationSettings.authorizationStatus != .authorized {
            application.registerForRemoteNotifications();
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var token = ""
        
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        
        let wvc = window?.rootViewController as? WebViewController;
        
        wvc?.handleDeviceToken(receivedDeviceToken: token);
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register:", error);
    }
}

