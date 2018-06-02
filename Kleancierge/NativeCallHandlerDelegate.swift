//
//  NativeCallHandlerDelegate.swift
//  Kleancierge
//
//  Created by Vincent Moley on 10/17/17.
//  Copyright © 2017 Vincent Moley. All rights reserved.
//

import Foundation

public protocol NativeCallHandlerDelegate : NSObjectProtocol {
    @available(iOS 8.0, *)
    func appLoaded();
    
    @available(iOS 8.0, *)
    func requestContactsAccess();
    
    @available(iOS 8.0, *)
    func updateCurrentUrl(url currentLocation: String);
    
    @available(iOS 8.0, *)
    func requestCurrentLocation();
}
