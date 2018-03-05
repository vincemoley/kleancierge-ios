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
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
        // --- local device --- //
        //ipAddress = "192.168.5.223"
        //url = "http://" + ipAddress + ":8080"
        
        // --- production --- //
        ipAddress = "app.kleancierge.com"
        url = "https://" + ipAddress
        
        // --- local - emulator --- //
        //url = "http://localhost:8080"
        
        initLoad = true
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
        webView = WKWebView(frame: CGRect(x: 0, y: statusBarHeight, width: view.bounds.maxX, height: view.bounds.maxY), configuration: webConfig)
        
        webView.allowsBackForwardNavigationGestures = true;
        webView.translatesAutoresizingMaskIntoConstraints = false;
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.addSubview(refreshControl)
        
        view.addSubview(webView);
        view.sendSubview(toBack: webView);
        
        var initialUrl = url
        
        if let cookieDictionary = UserDefaults.standard.dictionary(forKey: "cookieCache") {
            var cookieStr = "";
            
            for (key, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]){
                    if cookie.domain == ipAddress && key == "SESSION" {
                        cookieStr += "\(key)=\(cookie.value)"
                        
                        WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie, completionHandler: nil)
                    }
                }
            }
            
            if cookieStr.contains("SESSION"){
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
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("Received redirect to: \(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Error Loading WebView: \(error)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var cookieDictionary = [String : AnyObject]()
        
        if debugging {
            let response = navigationResponse.response as! HTTPURLResponse
            print("Response Code: \(response.statusCode)")
        }
        
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            cookies.forEach({ (cookie) in
                if self.debugging {
                    print("Response Cookie: \(cookie)")
                }
                cookieDictionary[cookie.name] = cookie.properties as AnyObject?
            })
            
            UserDefaults.standard.set(cookieDictionary, forKey: "cookieCache")
        }
        
        decisionHandler(WKNavigationResponsePolicy.allow);
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Kleancierge Alert", message: message, preferredStyle: .alert);
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler()
        }));
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func didPullToRefresh(sender: UIRefreshControl){
        if debugging {
            let webViewUrl = webView.url?.absoluteString ?? "NO WEBVIEW URL"
            print("Refresh: \(webViewUrl)")
        }
        
        webView.reload()
        sender.endRefreshing()
    }
    
    func appLoaded() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        
        appDelegate.registerForRemoteNotification();
    }
    
    func handleDeviceToken(receivedDeviceToken deviceToken: String){
        webView.evaluateJavaScript("saveUserNotificationDeviceToken('" + deviceToken + "', 'ios');", completionHandler: nil);
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
    
    public func reloadIfOnLogin(){
        if webView.url!.absoluteString.contains("login") {
            if debugging {
                print("Reloading webview b/c on login page")
            }
            
            webView.reload()
        }
    }
}
