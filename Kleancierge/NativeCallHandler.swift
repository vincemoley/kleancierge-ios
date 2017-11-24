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
    
    var delegate: NativeCallHandlerDelegate?;
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody: NSDictionary = message.body as? NSDictionary {
            if let innerBody: NSDictionary = messageBody["body"] as? NSDictionary {
                //print(innerBody);
                
                let type = innerBody["type"] as? String;
                
                if type == "apploaded" {
                    delegate?.appLoaded();
                } else if type == "opencontacts" {
                    delegate?.requestContactsAccess();
                } else {
                    print("unable to handle type: " + type!);
                }
            }
        }
    }}
