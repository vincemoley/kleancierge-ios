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

// https://medium.com/@felicity.johnson.mail/web-view-tutorial-swift-3-0-4a5f4f6858d3

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, NativeCallHandlerDelegate, CNContactPickerDelegate {

    var webView : WKWebView!;
    
    var webConfig: WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration();
            let userController = WKUserContentController();
            let nativeCallHandler = NativeCallHandler();
            
            nativeCallHandler.delegate = self;
            
            userController.add(nativeCallHandler, name: "onNativeCalled");
            
            webCfg.userContentController = userController;
            
            return webCfg;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // production
        let url = "https://www.kleancierge.com/login";
        
        // local - device
        // ip-address is found in advanced wifi section
        //let url = "http://172.20.10.3:8080/login";
        
        // local - emulator
        //let url = "http://localhost:8080/login";
        
        
        webView = WKWebView(frame: CGRect( x: 0,
                                           y: 20,
                                           width: self.view.frame.width,
                                           height: self.view.frame.height - 20 ),
                            configuration: webConfig);
        
        webView.allowsBackForwardNavigationGestures = true;
        
        webView.uiDelegate = self;
        webView.navigationDelegate = self;
        
        view.addSubview(webView);
        view.sendSubview(toBack: webView);
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url,
                                     cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                     timeoutInterval: 60.0)
            let session = URLSession.shared;
            
            let task = session.dataTask(with: request) { (data, response, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        self.webView.load(request);
                        
                        print("webview load");
                    }
                } else {
                    print("Error: \(String(describing: error))");
                }
            }
            
            task.resume();
        } else {
            print("URL NOT FOUND");
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription);
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //print("webview started");
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //print("webview loaded");
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
        
        //print("App Loaded.  Prompt to accept push notfications");
    }
    
    func handleDeviceToken(receivedDeviceToken deviceToken: String){
        webView.evaluateJavaScript("saveUserNotificationDeviceToken('" + deviceToken + "', 'ios');", completionHandler: nil);
    }
    
    func appBecameActiveReloadWebView(){
        self.webView.reload();
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
