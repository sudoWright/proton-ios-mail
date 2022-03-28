//
//  SettingsLockCoordinator.swift
//  ProtonMail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

class SettingsLockCoordinator {
    private let services: ServiceFactory

    private weak var navigationController: UINavigationController?

    enum Destination: String {
        case pinCodeSetup = "pincode_setup"
    }

    init(navigationController: UINavigationController?, services: ServiceFactory) {
        self.navigationController = navigationController
        self.services = services
    }

    func start() {
        let viewModel = SettingsLockViewModelImpl(biometricStatus: UIDevice.current, userCacheStatus: userCachedStatus)
        let viewController = SettingsLockViewController(viewModel: viewModel, coordinator: self)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .pinCodeSetup:
            let nav = UINavigationController()
            nav.modalPresentationStyle = .fullScreen
            let coordinator = PinCodeSetupCoordinator(nav: nav, services: self.services)
            coordinator.configuration = { vc in
                vc.viewModel = SetPinCodeModelImpl()
            }
            coordinator.start()
            self.navigationController?.present(nav, animated: true, completion: nil)
        }
    }
}
