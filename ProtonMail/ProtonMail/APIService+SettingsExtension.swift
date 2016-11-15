//
//  APIService+SettingsExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

/// Settings extension
extension APIService {
    
    private struct SettingPath {
        static let base = AppConstants.BaseAPIPath + "/settings"
    }
    

    
    func settingUpdateSignature(signature: String, completion: CompletionBlock) {
        let path = SettingPath.base + "/signature"
        let parameters = ["Signature" : signature]
        
        setApiVesion(1, appVersion: 1)
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
}


