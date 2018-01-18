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
    
    // production
    //var url = "https://www.kleancierge.com"
    
    // local - device
    // ip-address is found in advanced wifi section
    var url = "http://192.168.5.233:8080"
    
    // local - emulator
    //var url = "http://localhost:8080"
    
    var webView: WKWebView!
    var initLoad = false
    
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
        
        initLoad = true
    
        webView = WKWebView(frame: self.view.frame,
                            configuration: webConfig);
        
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
                    if key == "JSESSIONID" {
                        cookieStr += "\(key)=\(cookie.value)"
                    }
                    
                    storage.setCookie(cookie)
                }
            }
            
            if cookieStr.contains("JSESSIONID"){
                //print("Using User Detail Session Cookies") // debugging
                
                initialUrl += "/loggedIn"
                
                var request = URLRequest(url: URL(string: initialUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
                
                //print("Using UserDefaults Cookie: \(cookieStr)") // debugging
                
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
        
        headerFields.forEach { (key, value) in
            //print("Response Header: \(key)=\(value)") // debugging
        }
        //print("") // debugging
        
        decisionHandler(WKNavigationResponsePolicy.allow);
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //print("Navigate to: \(webView.url!)") // debugging
        
        let storage = WKWebsiteDataStore.default().httpCookieStore
        var policy = WKNavigationActionPolicy.allow
        
        storage.getAllCookies { (cookies) in
            cookies.forEach({ (cookie) in
                //print("Request cookie for \(webView.url!): \(cookie.name)=\(cookie.value)") // debugging
            })
            //print("") // debugging
        }
        
        if webView.url!.absoluteString.contains("loggedIn") {
            //print("Store cookies in case app is terminated") // debugging
            
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
                    //print("\(cookie)") // debugging
                    //print("Store cookie: \(cookie.name)=\(cookie.value)") // debugging
                    cookieDictionary[cookie.name] = cookie.properties as AnyObject?
                })
                
                userDefaults.set(cookieDictionary, forKey: "cookieCache")
                
                self.initLoad = false
            }
        } else if webView.url!.absoluteString.contains("login?is") {
            //print("Invalid Session - Clear User Detail Cookie Cache") // debugging
            
            let userDefaults = UserDefaults.standard
            
            userDefaults.removeObject(forKey: "cookieCache")
        }
        
        decisionHandler(policy)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription);
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //print("webview started") // debugging
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //print("webview loaded") // debugging
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
        
        //print("App Loaded.  Prompt to accept push notfications") // debugging
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
                    print("Not Authorized");
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
            
            //print(contact);
            
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
