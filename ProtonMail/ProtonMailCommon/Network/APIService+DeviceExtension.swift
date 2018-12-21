//
//  APIService+DeviceExtension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Crypto

extension APIService {
    fileprivate struct DevicePath {
        static let basePath = "/devices"
    }
    
    func device(registerWith settings: PushSubscriptionSettings, completion: CompletionBlock?) {
        
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        #if Enterprise
            #if DEBUG
                //let env = 20
                let env = 17  /// Enterprise dev certification build (fabric beta)
            #else
                //let env = 21
                let env = 7 ///Enterprise release certification build
            #endif
        #else
            // const PROVIDER_FCM_IOS = 4; // google firebase live
            // const PROVIDER_FCM_IOS_BETA = 5; //google firebase beta
            #if DEBUG
                //let env = 1
                let env = 16 /// apple store certificaiton dev build (dev)
            #else
                //let env = 2
                let env = 6  /// apple store release build (for apple store submit)
            #endif
        
        #endif
        let parameters = [
            "DeviceToken" : settings.token,
            "DeviceName" : UIDevice.current.name,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env,
            "PublicKey" : settings.encryptionKit.publicKey
        ] as [String : Any]
        
        request(method: .post,
                path: Constants.App.API_PATH + DevicePath.basePath,
                parameters: parameters,
                headers: ["x-pm-apiversion": 3],
                completion: completion)
    }
    
    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping CompletionBlock) {
        guard !userCachedStatus.isForcedLogout else {
            return
        }
        
        let parameters = [
            "DeviceToken": settings.token,
            "UID": settings.UID
        ]

        request(method: .delete,
                path: Constants.App.API_PATH + DevicePath.basePath,
                parameters: parameters,
                headers: ["x-pm-apiversion": 3],
                authenticated: false,
                completion: completion)
    }
}
