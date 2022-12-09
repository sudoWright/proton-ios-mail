//
//  SettingsViewModel.swift
//  Proton Mail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import MBProgressHUD
import ProtonCore_DataModel
import ProtonCore_Log

enum SettingDeviceSection: Int, CustomStringConvertible {
    case account
    case app
    case general
    case clearCache
    case induceSlowdown

    var description: String {
        switch self {
        case .account:
            return LocalString._account_settings
        case .app:
            return LocalString._app_settings
        case .general:
            return LocalString._app_general_settings
        case .clearCache:
            return LocalString._empty_cache
        case .induceSlowdown:
            return "Induce slowdown"
        }
    }
}

enum DeviceSectionItem: Int, CustomStringConvertible {
    case darkMode = 0
    case appPIN
    case swipeAction
    case combineContacts
    case alternativeRouting
    case browser
    case toolbar
    case applicationLogs

    var description: String {
        switch self {
        case .darkMode:
            return LocalString._dark_mode
        case .appPIN:
            return LocalString._app_pin
        case .combineContacts:
            return LocalString._combined_contacts
        case .browser:
            return LocalString._default_browser
        case .swipeAction:
            return LocalString._swipe_actions
        case .alternativeRouting:
            return LocalString._alternative_routing
        case .toolbar:
            return LocalString._toolbar_customize_general_title
        case .applicationLogs:
            return L11n.Settings.applicationLogs
        }
    }
}

enum GeneralSectionItem: Int, CustomStringConvertible {
    case notification = 0
    case language = 1

    var description: String {
        switch self {
        case .notification:
            return LocalString._push_notification
        case .language:
            return LocalString._app_language
        }
    }
}

final class SettingsDeviceViewModel {
    typealias Dependencies = HasUserManager
    & HasCleanCache
    & HasBiometricStatusProvider
    & HasLockCacheStatus
    & HasUserCachedStatus

    let sections: [SettingDeviceSection] = {
        var standardSections: [SettingDeviceSection] = [.account, .app, .general, .clearCache]
#if DEBUG_ENTERPRISE
        standardSections.append(.induceSlowdown)
#endif
        return standardSections
    }()

    private(set) var appSettings: [DeviceSectionItem] = [
        .darkMode,
        .appPIN,
        .combineContacts,
        .browser,
        .alternativeRouting,
        .swipeAction
    ]

    private(set) var generalSettings: [GeneralSectionItem] = [.notification, .language]

    private let dependencies: Dependencies

    private let induceSlowdownUseCase: InduceSlowdown

    var lockOn: Bool {
        dependencies.lockCacheStatus.isPinCodeEnabled || dependencies.lockCacheStatus.isTouchIDEnabled
    }

    var combineContactOn: Bool {
        dependencies.userCachedStatus.isCombineContactOn
    }

    var email: String {
        dependencies.user.defaultEmail
    }

    var name: String {
        let name = dependencies.user.defaultDisplayName
        return name.isEmpty ? self.email : name
    }

    var isDohOn: Bool {
        BackendConfiguration.shared.doh.status == .on
    }

    var appPINTitle: String {
        switch dependencies.biometricStatusProvider.biometricType {
        case .faceID:
            return LocalString._app_pin_with_faceid
        case .touchID:
            return LocalString._app_pin_with_touchid
        default:
            return LocalString._app_pin
        }
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        induceSlowdownUseCase = .init(user: dependencies.user)

        if UserInfo.isToolbarCustomizationEnable {
            appSettings.append(.toolbar)
        }

        appSettings.append(.applicationLogs)
    }

    func appVersion() -> String {
        var appVersion = "Unknown Version"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = "\(version)"
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = appVersion + " (\(build))"
        }
        return appVersion
    }

    func cleanCache(completion: ((Result<Void, NSError>) -> Void)?) {
        dependencies
            .cleanCache
            .callbackOn(.main)
            .execute(params: Void()) { result in
            switch result {
            case .success:
                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error as NSError))
            }
        }
    }

    func induceSlowdown() {
        Task {
            do {
                try await induceSlowdownUseCase.execute()
            } catch {
                SystemLogger.log(error: error, category: .artificialSlowdown)

                await MBProgressHUD.alert(errorString: error.localizedDescription)
            }
        }
    }
}
