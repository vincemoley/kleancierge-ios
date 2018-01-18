//
//  WebViewController.swift
//  Kleancierge
//
//  Created by Vincent Moley on 10/17/17.
//  Copyright © 2017 Vincent Moley. All rights reserved.
//

import UIKit
import WebKit
import Contacts
import ContactsUI
import UserNotifications

// https://medium.com/@felicity.johnson.mail/web-view-tutorial-swift-3-0-4a5f4f6858d3

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, NativeCallHandlerDelegate, CNContactPickerDelegate, URLSessionDelegate {
    
    var ipAddress:String = ""
    var url: String = ""
    
    var webView: WKWebView!
    var initLoad = false
    var debugging = false
    
    var webConfig: WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration()
            let userController = WKUserContentController()
            let nativeCallHandler = NativeCallHandler()
            
            nativeCallHandler.delegate = self;
            
            userController.add(nativeCallHandler, name: "onNativeCalled");
            
            webCfg.userContentController = userController;
            webCfg.websiteDataStore = WKWebsiteDataStore.default()
            
            return webCfg;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ipAddress = "www.kleancierge.com"
        ipAddress = "10.0.0.5"
            // local device
        url = "http:/" + ipAddress + ":8080"
            // production
        //url = "https://" + ipAddress
            // local - emulator
        //url = "http://localhost:8080"
        
        initLoad = true
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
        webView = WKWebView(frame: CGRect(x: 0, y: statusBarHeight, width: view.bounds.maxX, height: view.bounds.maxY), configuration: webConfig)
        
        webView.allowsBackForwardNavigationGestures = true;
        webView.translatesAutoresizingMaskIntoConstraints = false;
        
        webView.uiDelegate = self;
        webView.navigationDelegate = self;
        
        view.addSubview(webView);
        view.sendSubview(toBack: webView);
        
        let storage = WKWebsiteDataStore.default().httpCookieStore
        let userDefaults = UserDefaults.standard
        var initialUrl = url
        
        if let cookieDictionary = userDefaults.dictionary(forKey: "cookieCache") {
            var cookieStr = "";
            
            for (key, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]){
                    if cookie.domain == ipAddress {
                        if key == "JSESSIONID" {
                            cookieStr += "\(key)=\(cookie.value)"
                        }
                        
                        storage.setCookie(cookie)
                    }
                }
            }
            
            if cookieStr.contains("JSESSIONID"){
                initialUrl += "/loggedIn"
                
                var request = URLRequest(url: URL(string: initialUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
                
                if debugging {
                    print("Using UserDefaults Cookie: \(cookieStr)")
                }
                
                request.addValue(cookieStr, forHTTPHeaderField: "cookie")
                
                self.webView.load(request)
            } else {
                initialUrl += "/login"
                
                self.webView.load(URLRequest(url: URL(string: initialUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0))
            }
        } else {
            initialUrl += "/login"
            
            self.webView.load(URLRequest(url: URL(string: initialUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0))
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response as! HTTPURLResponse
        let headerFields = response.allHeaderFields as! [String:String]
        
        if debugging {
            headerFields.forEach { (key, value) in
                print("Response Header: \(key)=\(value)")
            }
            print("")
        }
        
        decisionHandler(WKNavigationResponsePolicy.allow);
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if debugging {
            print("Navigate to: \(webView.url!)")
        }
        
        let storage = WKWebsiteDataStore.default().httpCookieStore
        var policy = WKNavigationActionPolicy.allow
        
        if debugging {
            storage.getAllCookies { (cookies) in
                print("Request cookie for \(webView.url!):")
                cookies.forEach({ (cookie) in
                     //print("\(cookie.name)=\(cookie.value)")
                    print("\(cookie)")
                })
                print("")
            }
        }
        
        // Store cookies in case app is terminated
        if webView.url!.absoluteString.contains("loggedIn") {
            let userDefaults = UserDefaults.standard
            var cookieDictionary = [String : AnyObject]()
            
            storage.getAllCookies { (cookies) in
                if self.initLoad && cookies.count == 0 {
                    self.clearSession()
                    
                    policy = WKNavigationActionPolicy.cancel
                    
                    let loginUrl = self.url + "/login"
                    let request = URLRequest(url: URL(string: loginUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
                    
                    webView.load(request)
                }
                
                cookies.forEach({ (cookie) in
                    if self.debugging {
                        print("Store cookie: \(cookie)")
                        //print("Store cookie: \(cookie.name)=\(cookie.value)")
                    }
                    cookieDictionary[cookie.name] = cookie.properties as AnyObject?
                })
                
                userDefaults.set(cookieDictionary, forKey: "cookieCache")
                
                self.initLoad = false
            }
        } else if webView.url!.absoluteString.contains("login?is") {
            if debugging {
                print("Invalid Session - Clear User Detail Cookie Cache")
            }
            
            let userDefaults = UserDefaults.standard
            
            userDefaults.removeObject(forKey: "cookieCache")
        }
        
        decisionHandler(policy)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Kleancierge Alert", message: message, preferredStyle: .alert);
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler()
        }));
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    func appLoaded() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        
        appDelegate.registerForRemoteNotification();
    }
    
    func handleDeviceToken(receivedDeviceToken deviceToken: String){
        webView.evaluateJavaScript("saveUserNotificationDeviceToken('" + deviceToken + "', 'ios');", completionHandler: nil);
    }
    
    func appBecameActiveReloadWebView(){
        self.webView.reload();
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: "cookieCache")
    }
    
    func requestContactsAccess(){
        let entityType = CNEntityType.contacts;
        let authStatus = CNContactStore.authorizationStatus(for: entityType);
        
        if authStatus == CNAuthorizationStatus.notDetermined {
            let contactStore = CNContactStore.init();
            
            contactStore.requestAccess(for: entityType, completionHandler: { (success, nil) in
                if success {
                    self.openContacts();
                } else {
                    let alertController = UIAlertController(title: "Kleancierge Alert", message: "Unable to Access your Contacts", preferredStyle: .alert);
                    
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil));
                    
                    self.present(alertController, animated: true, completion: nil);
                }
            })
        } else if authStatus == CNAuthorizationStatus.authorized {
            self.openContacts();
        }
    }
    
    func openContacts(){
        let contactPicker = CNContactPickerViewController.init();
        
        contactPicker.delegate = self;
        
        self.present(contactPicker, animated: true, completion: nil);
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true){ }
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var customers = [NSDictionary]();
        
        for item in contacts {
            let contact = item as CNContact;
            var email: String = ""
            var mobile: String = ""
            
            if !contact.emailAddresses.isEmpty {
                let emailObject = contact.emailAddresses[0] as CNLabeledValue;
                let emailValue = emailObject.value(forKey: "value");
                
                email = (emailValue as! String?)!;
            }
            if !contact.phoneNumbers.isEmpty {
                let mainPhoneObject = contact.phoneNumbers[0] as CNLabeledValue;
                let mainPhoneNumber = mainPhoneObject.value as CNPhoneNumber;
                
                if mainPhoneObject.label == CNLabelPhoneNumberMobile {
                    mobile = mainPhoneNumber.stringValue;
                }
            }
            
            customers.append([
                "firstName": contact.givenName,
                "lastName": contact.familyName,
                "email": email,
                "mobile": mobile
            ]);
        }
        
        handleSaveCustomers(selectedCustomers: customers);
    }
    
    func handleSaveCustomers(selectedCustomers customers: [NSDictionary]){
        let data = try! JSONSerialization.data(withJSONObject: customers, options: [])
        let jsonString = String(data: data, encoding: String.Encoding.utf8)
        
        webView.evaluateJavaScript("saveCustomersFromIPhone(" + jsonString! + ", 'ios');", completionHandler: nil);
    }
}
