//
//  IdentificationCoordinator.swift
//  FoodViewer
//
//  Created by arnaud on 09/02/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit

final class MainCoordinator: Coordinator {

    var parentCoordinator: Coordinator? = nil

    var childCoordinators: [Coordinator] = []
    
    var childCoordinator: Coordinator? = nil
    
    var viewController: UIViewController? = nil
    
    private var _coordinatorViewController: MainViewController? {
        self.viewController as? MainViewController
    }
    
    private enum Pagetype: Int {
        case language = 0
    }

    init(with coordinator: Coordinator?) {
        self.viewController = MainViewController.instantiate()
        self.parentCoordinator = coordinator
    }

    init(with viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func show() {
        // Done in the viewController?
    }
/**
Shows a modal viewController with a tableView that allows the user to select ONE language.

The selected language will used to set the primary (main) language of the product.
*/
    func selectLanguage() {
        guard let languageCode = _coordinatorViewController?.currentLanguageCode else { return }
        let coordinator = SelectPairCoordinator.init(with:self,
                                                     original: [languageCode],
                              allPairs: OFFplists.manager.allLanguages,
                              multipleSelectionIsAllowed: false,
                              showOriginalsAsSelected: false,
                              tag: Pagetype.language.rawValue,
                              assignedHeader: TranslatableStrings.SelectedLanguages,
                              unAssignedHeader: TranslatableStrings.UnselectedLanguages,
                              undefinedText: TranslatableStrings.NoLanguageDefined)
        childCoordinators.append(coordinator)
        coordinator.show()
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

extension MainCoordinator: SelectPairCoordinatorProtocol {
    
    func selectPairViewController(_ sender:SelectPairViewController, selected strings: [String]?, tag:Int) {
        if let validStrings = strings {
            if tag == Pagetype.language.rawValue {
                if let newLanguageCode = validStrings.first {
                    _coordinatorViewController?.currentLanguageCode = newLanguageCode
                }
            }
        }
        sender.dismiss(animated: true, completion: nil)
    }

    func selectPairViewControllerDidCancel(_ sender:SelectPairViewController) {
        sender.dismiss(animated: true, completion: nil)
    }
    
}
