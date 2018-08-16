//
//  ServiceLevelCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ServiceLevelCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        var child: SomeCoordinator!
        
        switch next {
        case .buyMore:
            child = BuyMoreCoordinator() as? SomeCoordinator
            // setup controller
        default: fatalError()
        }
        
        return child
    }
    
    weak var controller: UIViewController! = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewController.self)
    
    enum Destination {
        case changePayedPlan(to: ServicePlanDetails)
        case chooseFirstPayedPlan(ServicePlanDetails)
        case currentPlan
        case buyMore
    }
}
