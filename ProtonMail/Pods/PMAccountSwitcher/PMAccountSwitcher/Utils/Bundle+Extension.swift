//
//  Bundle+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
extension Bundle {
    static let switchBundle = module ?? podsBundle ?? Bundle(for: AccountSwitcher.self)

    // Generated by SPM 5.3 on Xcode 12
    private static var module: Bundle? = {
        let bundleName = "PMAccountSwitcher_PMAccountSwitcher"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: AccountSwitcher.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        return nil
    }()

    private static var podsBundle: Bundle? {
        guard let url = Bundle(for: AccountSwitcher.self).url(forResource: "PMAccountSwitcher", withExtension: "bundle"), let bundle = Bundle(url: url) else {
            return nil
        }
        return bundle
    }
}
