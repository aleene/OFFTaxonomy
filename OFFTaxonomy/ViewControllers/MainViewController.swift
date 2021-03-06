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
    }
    
// MARK: - interface
    
    @IBOutlet weak var arborView: ArborView! {
        didSet {
            //arborView?.backgroundColor = .green
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
    
    @IBOutlet weak var selectTaxonomyButton: UIBarButtonItem! {
        didSet {
            selectTaxonomyButton?.title = self.currentTaxonomy?.filename ?? "Select Taxonomy"
        }
    }
    
    @IBAction func selectTaxonomyButtonTapped(_ sender: UIBarButtonItem) {
        self.mainCoordinator?.selectTaxonomy()
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
    public var currentTaxonomy: TaxonomyType? {
        didSet {
            if  currentTaxonomy != nil,
                currentTaxonomy != oldValue {
            
//TODO: TODO - load the map data (could be done in a background thread
                _system.deleteAll()
                let read = currentTaxonomy!.read()
                _system.addTaxonomy(particles: read.0, springs: read.1)
                _system.start(unpause: true)
            }
        }
    }

    public var mainCoordinator: MainCoordinator?

// MARK: - private variables
    
    private var _system = ATSystem()
    private var _scale = Constant.ViewScaleFactor
    private var _offset = Constant.ViewCenter
    private var _focusNode: ATParticle? {
        didSet {
            if _focusNode == nil {
                self.arborView?.focusParticleIndices = nil
            }
        }
    }
    private var _focusDistance = 2
    private var _focusParticleIndices: Set<Int> = [] {
        didSet {
            self.arborView?.focusParticleIndices = _focusParticleIndices
        }
    }

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
                        _ = _system.addParticle(with: node.key, and: node.value)
                    }
                }
                if let edges = mapJson.edges {
                    for edge in edges {
                        for country in edge.value {
                            _ = _system.addSpring(fromParticle: edge.key, toParticle: country.key, with: [:])
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
            let position = longPressGestureRecognizer.location(in: validView)
            _focusNode = _system.nearestParticle(physics: self.convertToPhysics(view: position),
                within: self.convertToPhysics(view: 30.0)!)
            let focus = UIMenuItem(title: "Focus", action: #selector(focusHandler(for:)))
            let debug = UIMenuItem(title: "Debug", action: #selector(debugHandler(for:)))
            let reset = UIMenuItem(title: "Reset", action: #selector(resetHandler(for:)))
            self.becomeFirstResponder()
            menuController.menuItems = [focus, debug, reset]
            menuController.showMenu(from: validView, rect: CGRect(origin: position, size: .zero))
        default: break
        }

    }

    @objc func focusHandler(for menuController: UIMenuController) {
        _focusParticleIndices = _system.determineFocusParticleIndices(around:_focusNode, within:_focusDistance)
        _system.start(unpause: true)
    }

    @objc func debugHandler(for menuController: UIMenuController) {
        self.arborView.isDebugDrawing = !self.arborView.isDebugDrawing
        _system.start(unpause: true)
    }

    @objc func resetHandler(for menuController: UIMenuController) {
        _focusNode = nil
        _system.start(unpause: true)
    }

    private var nearestNode: ATParticle?

    /// Allows to pickup a node and move it.
    @objc func oneFingerPan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard let view = panGestureRecognizer.view else { return }
        guard _scale != .zero else { return }
        switch panGestureRecognizer.state {
        case .began:
            let position = panGestureRecognizer.location(in: view)
            nearestNode = _system.nearestParticle(physics: self.convertToPhysics(view: position),
                within: self.convertToPhysics(view: 30.0)!)
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainCoordinator = MainCoordinator(with: self)
        // Configure simulation parameters, (take a copy, modify it, update the system when done.)
        var params = ATSystemParams()
        params.repulsion = 1000.0;
        params.stiffness = 600.0;
        params.friction  = 0.5;
        params.precision = 0.4;
        params.useBarnesHut = true
        
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
        self.arborView.isDebugDrawing = false
        self.addGestureRecognizers(to: self.arborView)
        self.currentTaxonomy = .languages
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
    
    public func convertToPhysics(view distance: CGFloat) -> CGFloat? {
        return distance / _scale
    }
    
    public func convertToPhysics(view size: CGSize) -> CGSize? {
        return size / _scale
    }
    
    public func convertToPhysics(view rect: CGRect) -> CGRect? {
        guard self.convertToPhysics(view: rect.size) != .zero else { return nil }
        return CGRect(origin: self.convertToPhysics(view: rect.origin),
                      size: self.convertToPhysics(view: rect.size)!)
    }
    
    
    public func convertToPhysics(view point: CGPoint) -> CGPoint {
        if _scale == .zero {
            return .zero
        }
        let midPoint = self.arborView.bounds.size.halved.asCGPoint
        let translate = point - midPoint - _offset
        let newPoint = translate.divide(by: _scale)!
        return newPoint
    }

    /// Convert a physics distance to a screen distance
    public func convertToView(physics distance: CGFloat) -> CGFloat {
        return distance * _scale
    }

    /// Convert a physics size to a screen size
    public func convertToView(physics size: CGSize) -> CGSize {
        return size * _scale
    }

    /// Convert a physics point to a screen point
    public func convertToView(physics point: CGPoint) -> CGPoint {
        let mid = self.arborView.bounds.size.halved.asCGPoint
        return point * _scale + mid + _offset
    }

    public func convertToView(physics rect: CGRect) -> CGRect {
        return CGRect(origin: convertToView(physics: rect.origin),
                      size: convertToView(physics: rect.size))
    }

}
