//
//  SelectTaxonomyViewController.swift
//  OFFTaxonomy
//
//  Created by arnaud on 04/05/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation
//
//  SetSortOrderViewController.swift
//  FoodViewer
//
//  Created by arnaud on 25/10/2017.
//  Copyright © 2017 Hovering Above. All rights reserved.
//

import UIKit

protocol SelectTaxonomyCoordinatorProtocol {
/**
Inform the protocol delegate that no data has been selected.
- Parameters:
     - sender : the `SelectTaxonomyViewController` that called the function.
*/
    func selectTaxonomyViewControllerDidCancel(_ sender:SelectTaxonomyViewController)
    /**
    Inform the protocol delegate that a date has been selected.
    - Parameters:
        - sender : the `SelectTaxonomyViewController` that called the function.
        - taxonomy : the selected taxonomy
    */
    func selectTaxonomyViewController(_ sender:SelectTaxonomyViewController, selected taxonomy: TaxonomyType)
}

class SelectTaxonomyViewController: UIViewController {
    
// MARK: - constants
    
    private struct Constant {
        static let RowOffset = 1
    }
    
// MARK: - external functions
    
    public func configure(current: TaxonomyType?) {
        _current = current
    }
    
    public var protocolCoordinator: SelectTaxonomyCoordinatorProtocol? = nil
    
    public weak var coordinator: Coordinator? = nil

//  MARK: interface elements
    
    @IBOutlet weak var pickerView: UIPickerView! {
        didSet {
            pickerView.dataSource = self
            pickerView.delegate = self
        }
    }
        
//  MARK : private variables

    private var _descriptions: [String] {
        return TaxonomyType.allCases.map { $0.filename } .sorted()
    }
    public var _selected: TaxonomyType? = nil
    public var _current: TaxonomyType? = nil


    // MARK: - ViewController Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //navItem.title = TranslatableStrings.Select
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        coordinator?.viewControllerDidDisappear(self)
        super.viewDidDisappear(animated)
    }

}

extension SelectTaxonomyViewController: UIPickerViewDelegate {

    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        _selected = row > 0 ? TaxonomyType.allCases[row - Constant.RowOffset] : nil
        if let validSelected = _selected {
            self.protocolCoordinator?.selectTaxonomyViewController(self, selected: validSelected)
        }
    }

}

extension SelectTaxonomyViewController:UIPickerViewDataSource {
        internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return TaxonomyType.allCases.count + 1
        }
        
        internal func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            
            if row == 0 {
                return "---"
            } else {
                return TaxonomyType.allCases[row - Constant.RowOffset].filename
            }
        }

}
