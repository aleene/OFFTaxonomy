//
//  ViewController.swift
//  Atlas
//
//  Created by arnaud on 17/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    
// MARK: - constants
    
    private struct Constant {
        /// Ratio physics size to view size. Note is very sensitive
        static let ViewScaleFactor = CGFloat(20.0)
        static let ViewCenter = CGPoint.zero
        static let OpenFoodFactsExtension = "txt"
        static let PlistExtension = "plist"
        static let TaxonomyKey = "Taxonomy"
        static let Language = "en"
        static let LanguageDivider = ":"
        struct FileName {
            static let Allergens = "Allergens"
            static let Additives = "Additives"
            static let AminoAcids = "Amino_acids"
            static let Brands = "Brands"
            static let Countries = "Countries"
            static let Categories = "Categories"
            static let Labels = "GlobalLabels"
            static let Languages = "Languages"
            static let Ingredients = "Ingredients"
            static let Minerals = "Minerals"
            static let Nucleotides = "Nucleotides"
            static let Nutrients = "Nutriments"
            static let OtherNutritionalSubstances = "Other_nutritional_substances"
            static let Processes = "Processes"
            static let Vitamins = "Vitamins"
            static let States = "States"
        }
    }
    
// MARK: - interface
    
    @IBOutlet weak var arborView: ArborView! {
        didSet {
            arborView?.backgroundColor = .green
            arborView?.delegate = self
        }
    }
    @IBOutlet weak var languageButton: UIBarButtonItem! {
        didSet {
            languageButton?.title = currentLanguageCode
        }
    }
    
    @IBAction func languageButtonTapped(_ sender: UIBarButtonItem) {
        self.mainCoordinator?.selectLanguage()
    }
    
// MARK: - public variables

    /// Needed in order to show UIMenuController
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    public var currentLanguageCode = "en" {
        didSet {
            self.arborView?.languageCode = currentLanguageCode
            self.languageButton?.title = currentLanguageCode
        }
    }
    
    public var mainCoordinator: MainCoordinator?

// MARK: - private variables
    
    private var _system = ATSystem()
    private var _scale = Constant.ViewScaleFactor
    private var _offset = Constant.ViewCenter

// MARK: - private functions

    private func loadMapData() {
        guard let path = Bundle.main.path(forResource: "process", ofType: "json") else {
            print("Please include america.json in the project resources.");
            return
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
        
            do {
                let mapJson = try decoder.decode(Map.self, from:data)
                if let nodes = mapJson.nodes {
                    for node in nodes {
                        _ = _system.addNode(with: node.key, and: node.value)
                    }
                }
                if let edges = mapJson.edges {
                    for edge in edges {
                        for country in edge.value {
                            _ = _system.addEdge(fromNode: edge.key, toNode: country.key, with: [:])
                        }
                    }
                }
            } catch let error {
                print (error.localizedDescription)
                print("Could not parse JSON file.");

            }
        } catch let error {
            print (error.localizedDescription)
            print("Could not load NSData from file.");
        }

    }

    private func addGestureRecognizers(to view: UIView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MainViewController.twoFingerPan(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.maximumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        arborView.addGestureRecognizer(panGestureRecognizer)

        let singleFingerPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MainViewController.oneFingerPan(_:)))
        singleFingerPanGestureRecognizer.minimumNumberOfTouches = 1
        singleFingerPanGestureRecognizer.maximumNumberOfTouches = 1
        singleFingerPanGestureRecognizer.delegate = self
        arborView.addGestureRecognizer(singleFingerPanGestureRecognizer)

        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(MainViewController.pinch(_:)))
        pinchGesture.delegate = self
        arborView.addGestureRecognizer(pinchGesture)

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showTouchMenu(for:)))
        arborView.addGestureRecognizer(longPressGestureRecognizer)

    }

// MARK: - @objc methods
    
    /// display a menu with a single item to allow the simulation to be reset
    @objc func showTouchMenu(for longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let validView = longPressGestureRecognizer.view else { return }
        switch longPressGestureRecognizer.state {
        case .began:
            let menuController = UIMenuController.shared
            let debugMenuItem = UIMenuItem(title: "Debug", action: #selector(debugHandler(for:)))
            let location = longPressGestureRecognizer.location(in: validView)
            self.becomeFirstResponder()
            menuController.menuItems = [debugMenuItem]
            menuController.showMenu(from: validView, rect: CGRect(origin: location, size: .zero))
        default: break
        }

    }

    @objc func debugHandler(for menuController: UIMenuController) {
        self.arborView.isDebugDrawing = !self.arborView.isDebugDrawing
    }
    
    private var nearestNode: ATNode?

    /// Allows to pickup a node and move it.
    @objc func oneFingerPan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard let view = panGestureRecognizer.view else { return }
        guard _scale != .zero else { return }
        switch panGestureRecognizer.state {
        case .began:
            let position = panGestureRecognizer.location(in: view)
            nearestNode = _system.nearestNode(physics: self.physicsCoordinate(for: position),
                within: self.physicsCoordinate(for: 30.0)!)
        case .changed:
            guard let nodePosition = nearestNode?.position else { break }
            nearestNode?.position = nodePosition + (panGestureRecognizer.translation(in: view) / _scale)!
            panGestureRecognizer.setTranslation(.zero, in: view)
        default: break
        }
        
        // start the simulation
        _system.start(unpause: true)

    }
    
    /// shift the piece's center by the pan amount
    /// reset the gesture recognizer's translation to {0, 0} after applying so the next callback is a delta from the current position
    @objc func twoFingerPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }

        switch gestureRecognizer.state {
        case .began, .changed:
            let translation = gestureRecognizer.translation(in: view)
            //view.center = view.center + translation
            _offset = _offset + translation
            gestureRecognizer.setTranslation(.zero, in: view)
        default: break
        }
        
        _system.start(unpause: true)
    }

    /// scale the piece by the current scale
    /// reset the gesture recognizer's scale to 0 after applying so the next callback is a delta from the current scale
    @objc func pinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }
        guard view.bounds.size != .zero else { return }
        //self.adjustAnchorPoint(for: gestureRecognizer)
        switch gestureRecognizer.state {
        case .began, .changed:
            // where was the pinch located?
            let locationInView = gestureRecognizer.location(in: view)
            let midPoint = view.bounds.halved.asCGPoint
            _offset = midPoint - locationInView

            _scale *= gestureRecognizer.scale
            gestureRecognizer.scale = 1
            _system.start(unpause: true)
        default: break
        }
    }
    
    // scale and rotation transforms are applied relative to the layer's anchor point
    // this method moves a gesture recognizer's view's anchor point between the user's fingers
    private func adjustAnchorPoint(for gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            guard let view = gestureRecognizer.view else { break }
            guard view.bounds.size != .zero else { break }
            let locationInView = gestureRecognizer.location(in: view)
            let locationInSuperView = gestureRecognizer.location(in:view.superview)
            view.layer.anchorPoint = (locationInView / view.bounds.size)!
            view.center = locationInSuperView
        default: break
        }
    }
    
    func readOFFTaxonomy(_ taxonomyIdentifier: String) -> BHTaxonomy {
        
        let offTaxonomy = BHTaxonomy()
        
        // read file in /InputTaxonomies/Allergens.txt
        if let path = Bundle.main.path(forResource: taxonomyIdentifier, ofType: Constant.OpenFoodFactsExtension) {
            
            // if there is a file, a corresponding struct can be created
            do {
                let file = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
                var currentSection = Section()
                
                // transform file in Array with lines
                let fileLines = file.components(separatedBy: NSCharacterSet.newlines)
                
                // analyse line by line
                for line in fileLines {
                    // is it a taxonomy line?
                    guard !line.hasPrefix("== Taxonomy") else { continue }
                    guard !line.hasPrefix("2 letters") else { continue }
                    guard !line.hasPrefix("Taxonomy") else { continue }
                    guard !line.hasPrefix("</pre>") else { continue }
                    guard !line.hasPrefix("<pre>") else { continue }
                    guard !line.hasPrefix("synonyms") else { continue }
                    guard !line.hasPrefix("e_number") else { continue }
                    guard !line.hasPrefix("wikidata") else { continue }
                    guard !line.hasPrefix("colour_index") else { continue }
                    guard !line.hasPrefix("#") else { continue }
                    guard !line.hasPrefix("country") else { continue }
                    guard !line.hasPrefix("official") else { continue }
                    guard !line.hasPrefix("stopwords") else { continue }
                    guard !line.hasPrefix("pnns_group_1") else { continue }
                    guard !line.hasPrefix("pnns_group_2") else { continue }
                    guard !line.hasPrefix("grapevariety") else { continue }
                    guard !line.hasPrefix("region") else { continue }
                    guard !line.hasPrefix("instanceof") else { continue }
                    guard !line.hasPrefix("address") else { continue }
                    guard !line.hasPrefix("city") else { continue }
                    guard !line.hasPrefix("name") else { continue }
                    guard !line.hasPrefix("postalcode") else { continue }
                    guard !line.hasPrefix("website") else { continue }
                    
                    // where are we in the taxonomy?
                    // either a new Vertex OR a new leaf
                    //
                    // find first empty element or newline?
                    if (line.isEmpty) {
                        // this will be the start of a new section and Vertex
                        
                        // wrap up the previous section
                        if !currentSection.leaves.isEmpty {
                            currentSection.key = currentSection.normalizeKey()
                            offTaxonomy.sections.append(currentSection)
                        }
                        
                        // reset Vertex section
                        currentSection = Section()
                        
                    } else if (line.hasPrefix("<")) {
                        // a section preceding with a < defines a parent.
                        // a section might have multiple parents.
                        let firstSplit = line.split{ $0 == "<" }.map(String.init)
                        // what comes after the <, is the key for the parent
                        currentSection.parentKeys.append(firstSplit[0])
                        
                    } else if (line.hasPrefix("§")) {
                        // a section preceding with a < defines a parent.
                        // a section might have multiple parents.
                        let firstSplit = line.split{ $0 == "§" }.map(String.init)
                        // what comes after the §, is the key
                        currentSection.key = firstSplit[0]

                    } else {
                        // a standard line should be split in a language and values part
                        let firstSplit = line.split{ $0 == ":" }.map(String.init)
                        
                        // language part (colon) is missing
                        guard firstSplit.count > 1 else {
                            print("Wrong markup in line \"\(firstSplit[0])\" (: missing?)")
                            continue
                        }
                        
                        let language = firstSplit[0]

                        // the values part should be split in separate values
                        if firstSplit.count > 1 {
                            currentSection.leaves[language]  = firstSplit[1].split{ $0 == "," }.map(String.init)
                        }
                        // set the key for this Vertex / section as the first pass language
                        if currentSection.key.isEmpty {
                            currentSection.key = currentSection.alternativeKey()
                        }
                    }
                    
                } // end for
                
                // wrap up the last entry if needed
                // is this actually needed? If an empty line is missing?
                if !currentSection.leaves.isEmpty {
                    print("Empty line missing")
                    currentSection.key = currentSection.normalizeKey()

                    offTaxonomy.sections.append(currentSection)
                }
            } // end do
            catch {/* error handling here */
                print("Error reading file")
            }
        } // end if

        return offTaxonomy
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainCoordinator = MainCoordinator(with: self)
        // Configure simulation parameters, (take a copy, modify it, update the system when done.)
        var params = ATSystemParams()
        params.repulsion = 1000.0;
        params.stiffness = 600.0;
        params.friction  = 0.5;
        params.precision = 0.4;
        params.useBarnesHut = false
        
        _system.parameters = params
        // Setup the view bounds, needed to so the simulation
        _system.viewBounds = self.arborView.bounds
        // leave some space at the bottom and top for text
        _system.viewPadding = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        // have the ‘camera’ zoom somewhat slowly as the graph unfolds
        _system.viewTweenStep = 0.2
        // set this controller as the system's delegate
        _system.delegate = self
        // DEBUG
        self.arborView.system = _system
        self.arborView.isDebugDrawing = true
        self.addGestureRecognizers(to: self.arborView)
   
        // load the map data
        //self.loadMapData()
        let taxonomy = readOFFTaxonomy(Constant.FileName.Processes)
        // create ATNodes
        let nodes = taxonomy.createNodes()
        nodes.forEach({_ = _system.addNode(with: $0.name!, and: $0.userData)  })
        // create edges from the off file
        let edges = taxonomy.createEdges()
        edges.forEach({ _ = _system.addEdge($0) })
        _system.start(unpause: true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The correct size of arborView is not yet known
    }

}

// MARK: - ATDebugRendering protocol

extension MainViewController : ATDebugRendering {
    
    func redraw() {
        self.arborView.setNeedsDisplay()
    }

}

// MARK: - UIGestureRecognizerDelegate protocol

extension MainViewController: UIGestureRecognizerDelegate {
    
    /// ensure that the pinch, pan and rotate gesture recognizers on a particular view can all recognize simultaneously prevent other gesture recognizers from recognizing simultaneously
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let validView = gestureRecognizer.view else { return false }
        guard let validOtherView = otherGestureRecognizer.view else { return false }
        
        // if the gesture recognizers's view isn't ours, don't allow simultaneous recognition
        guard validView == self.arborView else { return false }
        
        // if the gesture recognizers are on different views, don't allow simultaneous recognition
        guard validView == validOtherView else { return false }
        
        // if either of the gesture recognizers is the long press, don't allow simultaneous recognition
        if gestureRecognizer is UILongPressGestureRecognizer
        || otherGestureRecognizer is UILongPressGestureRecognizer { return false }
        
        // if either of the gesture recognizers is the pan, don't allow simultaneous recognition
        if gestureRecognizer is UIPanGestureRecognizer
            || otherGestureRecognizer is UIPanGestureRecognizer { return false }
        
        return true

    }
}


// MARK: - ArborViewDelegate protocol

extension MainViewController: ArborViewProtocol {
    
    func physicsCoordinate(for screenDistance: CGFloat) -> CGFloat? {
        return screenDistance / _scale
    }
    
    func physicsCoordinate(for screenSize: CGSize) -> CGSize? {
        return screenSize / _scale
    }
    
    func physicsCoordinate(for screenRect: CGRect) -> CGRect? {
        guard self.physicsCoordinate(for: screenRect.size) != .zero else { return nil }
        return CGRect(origin: self.physicsCoordinate(for: screenRect.origin),
                      size: self.physicsCoordinate(for: screenRect.size)!)
    }
    
    
    public func physicsCoordinate(for screenPoint: CGPoint) -> CGPoint {
        if _scale == .zero {
            return .zero
        }
        let midPoint = self.arborView.bounds.size.halved.asCGPoint
        let translate = screenPoint - midPoint - _offset
        let newPoint = translate.divide(by: _scale)!
        return newPoint
    }

    /// Convert a physics distance to a screen distance
    public func screenCoordinate(for physicsDistance: CGFloat) -> CGFloat {
        return physicsDistance * _scale
    }

    /// Convert a physics size to a screen size
    public func screenCoordinate(for physicsSize: CGSize) -> CGSize {
        return physicsSize * _scale
    }

    /// Convert a physics point to a screen point
    public func screenCoordinate(for physicsPoint: CGPoint) -> CGPoint {
        let mid = self.arborView.bounds.size.halved.asCGPoint
        return physicsPoint * _scale + mid + _offset
    }

    public func screenCoordinate(for physicsRect: CGRect) -> CGRect {
        return CGRect(origin: screenCoordinate(for: physicsRect.origin),
                      size: screenCoordinate(for: physicsRect.size))
    }

}
