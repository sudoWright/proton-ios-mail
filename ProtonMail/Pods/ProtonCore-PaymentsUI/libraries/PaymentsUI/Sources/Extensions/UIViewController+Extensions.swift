//
//  UIViewController+Extensions.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations

extension UIViewController {
    func showBanner(message: String, position: PMBannerPosition) {
        let banner = PMBanner(message: message, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
        banner.addButton(text: CoreString._hv_ok_button) { _ in
            banner.dismiss()
        }
        PMBanner.dismissAll(on: self)
        banner.show(at: position, on: self)
    }
}
