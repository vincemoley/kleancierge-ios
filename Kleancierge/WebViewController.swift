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
import CoreLocation

// https://medium.com/@felicity.johnson.mail/web-view-tutorial-swift-3-0-4a5f4f6858d3

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, NativeCallHandlerDelegate, CNContactPickerDelegate, URLSessionDelegate, CLLocationManagerDelegate {
    var spinner = SpinnerViewController()
    
    var ipAddress:String = ""
    var url: String = ""
    let LOGIN: String = "/login"
    let LOGGED_IN: String = "/loggedIn#/"
    let SESSION_KEY: String = "SESSION"
    let COOKIE_CACHE_KEY: String = "cookieCache"
    let CURRENT_URL: String = "currentLocation"
    let MAX_TIMEOUT = 60.0 // seconds
    
    let manager = CLLocationManager()
    
    var webView: WKWebView!
    var debugging = false
    var debugLoadWebView = false
    var debugResponse = false
    
    var webConfig: WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration()
            let userController = WKUserContentController()
            let nativeCallHandler = NativeCallHandler()
            
            nativeCallHandler.delegate = self
            
            userController.add(nativeCallHandler, name: "onNativeCalled")
            
            webCfg.userContentController = userController
            webCfg.websiteDataStore = WKWebsiteDataStore.default()
            
            return webCfg;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
        // --- local device --- //
        //ipAddress = "10.0.0.188"
        //url = "http://" + ipAddress + ":8080"
        
        // --- production --- //
        ipAddress = "app.kleancierge.com"
        url = "https://" + ipAddress
        
        // --- local - emulator --- //
        //url = "http://localhost:8080"
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
        webView = WKWebView(frame: CGRect(x: 0, y: statusBarHeight, width: view.bounds.maxX, height: view.bounds.maxY), configuration: webConfig)
        
        webView.allowsBackForwardNavigationGestures = true;
        webView.translatesAutoresizingMaskIntoConstraints = false;
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.addSubview(refreshControl)
        
        view.addSubview(webView);
        view.sendSubview(toBack: webView);
        
        //bustCache()
        
        if let cookieDictionary = UserDefaults.standard.dictionary(forKey: COOKIE_CACHE_KEY) {
            for (key, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]){
                    if cookie.domain == ipAddress && key == SESSION_KEY {
                        WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie){
                            self.loadWebView(cookieStr: "\(key)=\(cookie.value)")
                        }
                    } else {
                        UserDefaults.standard.removeObject(forKey: COOKIE_CACHE_KEY)
                        
                        self.loadWebView(cookieStr: "")
                    }
                } else {
                    self.loadWebView(cookieStr: "")
                }
            }
        } else {
            self.loadWebView(cookieStr: "")
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if debugging {
            print("\(webView.url!.absoluteString) page req sent")
        }
        showSpinner()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if debugging {
            print("\(webView.url!.absoluteString) page req rec'd")
        }
        hideSpinner()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let webViewUrl = webView.url?.absoluteString ?? "No URL";
        
        if debugging {
            print("\(webViewUrl) page failed")
        }
        
        hideSpinner()
        
        if error.localizedDescription.contains("Could not connect to the server") {
            navigateToConnectivity(url: webViewUrl, origin: "webview navigation failed")
        }
        
        print("Error Loading WebView: \(error)")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("Received redirect to: \(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response as! HTTPURLResponse
         
        if response.statusCode != 200 {
            if debugResponse {
                print("response rec'd but NOT 200")
            }
            
            navigateToConnectivity(url: response.url!.absoluteString, origin: "webview response")
        } else {
            UserDefaults.standard.set(response.url?.absoluteString, forKey: CURRENT_URL)
            
            var cookieDictionary = [String : AnyObject]()
            
            if debugResponse {
                print("Response Code: \(String(describing: response.url?.absoluteString))")
                print("Response Code: \(response.statusCode)")
            }
            
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
                cookies.forEach({ (cookie) in
                    if self.debugResponse {
                        print("Response Cookie: \(cookie)")
                    }
                    cookieDictionary[cookie.name] = cookie.properties as AnyObject?
                })
                
                UserDefaults.standard.set(cookieDictionary, forKey: self.COOKIE_CACHE_KEY)
            }
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
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func didPullToRefresh(sender: UIRefreshControl){
        if debugging {
            let webViewUrl = webView.url?.absoluteString ?? "NO WEBVIEW URL"
            print("Refresh: \(webViewUrl)")
        }
        
        bustCache()
        
        sender.endRefreshing()
        
        loadWebView(cookieStr: "")
    }
    
    func bustCache() {
        let cacheTypes = Set<String>([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let store = WKWebsiteDataStore.default()
        
        store.fetchDataRecords(ofTypes: cacheTypes) { (record) in
            store.removeData(ofTypes: cacheTypes, for: record){ }
        }
        
        //print("!!! REMOVING ALL PERSISTENT USER INFO, INCLUDING SESSION & CURRENT LOCATION !!!")
        //UserDefaults.standard.removeObject(forKey: COOKIE_CACHE_KEY)
        //UserDefaults.standard.removeObject(forKey: CURRENT_URL)
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
        let contactPicker = CNContactPickerViewController();
        
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation();
        
        if let location = locations.first {
            let dict = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ];
            
            let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
            
            webView.evaluateJavaScript("storeUserCoords(\(jsonString))", completionHandler: nil);
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func handleSaveCustomers(selectedCustomers customers: [NSDictionary]){
        let data = try! JSONSerialization.data(withJSONObject: customers, options: [])
        let jsonString = String(data: data, encoding: String.Encoding.utf8)
        
        webView.evaluateJavaScript("saveCustomersFromIPhone(" + jsonString! + ", 'ios');", completionHandler: nil);
    }
    
    public func reloadIfOnLogin(){
        /*
        let currentUrl = webView.url?.absoluteString ?? ""
        let homeUrl = url + LOGGED_IN
        
        if currentUrl != "" && (currentUrl.contains("login") || currentUrl == homeUrl) {
            if debugging {
                print("Reloading webview b/c on login or home page")
            }
            
            loadWebView(cookieStr: "")
        }
        */
    }
    
    public func redirectFromWebsite(url redirectUrl: String){
        self.webView.load(URLRequest(url: URL(string: url + redirectUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: MAX_TIMEOUT))
    }
    
    func requestCurrentLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation();
        manager.startUpdatingLocation();
    }
    
    func updateCurrentUrl(url currentUrl: String) {
        if debugging {
            print("Update current location: \(currentUrl)")
        }
        UserDefaults.standard.set(currentUrl, forKey: CURRENT_URL)
    }
    
    func loadWebView(cookieStr: String){
        var currentLocation = UserDefaults.standard.value(forKey: CURRENT_URL) as? String
        
        if currentLocation == nil || !currentLocation!.contains(ipAddress){
            currentLocation = url + LOGGED_IN;
        }
        
        if debugLoadWebView {
            print("Load Web View: \(currentLocation!)")
        }
        
        var request = URLRequest(url: URL(string: currentLocation!)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: MAX_TIMEOUT)
        
        if cookieStr != "" {
            if debugLoadWebView {
                print("Using UserDefaults Cookie: \(cookieStr)")
            }
            request.addValue(cookieStr, forHTTPHeaderField: "cookie")
        }
        
        self.webView.load(request)
    }
    
    func showSpinner(){
        if childViewControllers.count == 0 {
            spinner.willMove(toParentViewController: self)
            addChildViewController(spinner)
            view.addSubview(spinner.view)
            spinner.didMove(toParentViewController: self)
        }
    }
    
    func hideSpinner(){
        if childViewControllers.count > 0 {
            spinner.removeFromParentViewController()
            spinner.willMove(toParentViewController: nil)
            spinner.view.removeFromSuperview()
        }
    }
    
    func navigateToConnectivity(url: String, origin: String){
        if presentedViewController == nil {
            let alert = UIAlertController(title: "Unable to connect to Kleancierge", message: "Due to connectivity issues the app is unable to connect to Kleancierge\r\r" + url + "\r\r" + origin, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Attempt To Reconnect", style: .cancel, handler: { (action: UIAlertAction!) in
                self.loadWebView(cookieStr: "")
            }))
            
            present(alert, animated: true, completion: nil)

            /*
            // This solution does not work b/c it causes the request, event w/ the session cookie, to be denied and redirected to login
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "connectivityView")
            
            present(nextViewController, animated:true, completion:nil)
            */
        }
    }
    
    func requestSent(url: String) {
        if debugging {
            print("req sent " + url)
        }
        showSpinner()
    }
    
    func requestTimeout(url: String) {
        if debugging {
            print("req timeout" + url)
        }
        hideSpinner()
        navigateToConnectivity(url: url, origin: "webapp timeout")
    }
    
    func responseReceived() {
        if debugging {
            print("resp rec'd")
        }
        hideSpinner()
    }
}
