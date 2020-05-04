//
//  File.swift
//  OFFTaxonomy
//
//  Created by arnaud on 04/05/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit
/**
This class coordinates the viewControllers initiated by `SelectTaxonomyCoordinator` and their corresponding interaction flow.
 
 The interaction flow between the parent coordinator and this coordinator is handled by the parent coordinator through a extension. This interaction flow is defined as a protocol in the viewController coordinated by THIS class.
 
 - Important
 The parent coordinator must be passed on to the coordinated viewController and will be used for any protocol methods.

Variables:
 - `parentCoordinator`: the parent is the owner of this coordinator and the root for the associated viewController;
 - `childCoordinators`: the other coordinators that are required in child viewControllers;
 - `viewController`: the `SelectPairViewController` that is managed;
 
Functions:
  - `init(with:)` the initalisation method of this coordinator AND the corresponding viewController.
 
 - parameters:
    - with:  the parent Coordinator;
 
  - `init(with:original:allPairs:multipleSelectionIsAllowed:showOriginalsAsSelected:tag:assignedHeader:unAssignedHeader:undefinedText:)` the convenience init method, which sets up the corresponding viewController.
 
 - parameters:
    - with: the parent coordinator;
    - current: the currently selected taxonomy;

 - `show()` - show the managed viewController from the parent viewController view stack. The viewController is push on a navigation controller.

 Managed viewControllers:
 - none
*/
final class SelectTaxonomyCoordinator: Coordinator {
        
    weak var parentCoordinator: Coordinator? = nil
    /// The child coordinators currently managed by this coordinator. If the child viewcontroller dispaaears this coordinator is no longer needed.
    var childCoordinators: [Coordinator] = []

    var viewController: UIViewController? = nil
        
    var coordinatorViewController: SelectTaxonomyViewController? {
        self.viewController as? SelectTaxonomyViewController
    }

    init(with coordinator: Coordinator?) {
        self.parentCoordinator = coordinator
        self.viewController = SelectTaxonomyViewController.instantiate()
        if let protocolCoordinator = coordinator as? SelectTaxonomyCoordinatorProtocol {
            self.coordinatorViewController?.protocolCoordinator = protocolCoordinator
        } else {
            print("SelectTaxonomyCoordinator: coordinator does not conform to protocol")
        }
    }
    
    // pass on the data
    convenience init(with coordinator: Coordinator?, current: TaxonomyType) {
        self.init(with: coordinator)
        self.coordinatorViewController?.configure(
            current: current)
    }

    func show() {
        self.parentCoordinator?.presentAsFormSheet(self.viewController)
    }
    
    /// The viewController informs its owner that it has disappeared
    func viewControllerDidDisappear(_ sender: UIViewController) {
        if self.childCoordinators.isEmpty {
            self.viewController = nil
            informParent()
        }
    }
    
    /// A child coordinator informs its owner that it has disappeared
    func canDisappear(_ coordinator: Coordinator) {
        if let index = self.childCoordinators.lastIndex(where: ({ $0 === coordinator }) ) {
            self.childCoordinators.remove(at: index)
            informParent()
        }
    }
    
    private func informParent() {
        if self.childCoordinators.isEmpty
            && self.viewController == nil {
            parentCoordinator?.canDisappear(self)
        }
    }
}

