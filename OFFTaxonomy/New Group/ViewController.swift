//
//  ViewController.swift
//  Atlas
//
//  Created by arnaud on 17/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
// MARK: - interface
    
    @IBOutlet weak var arborView: ArborView!
    
// MARK: - public variables

    /// Needed in order to show UIMenuController
    override var canBecomeFirstResponder: Bool {
        true
    }

// MARK: - private variables
    
    private var _system = ATSystem()

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
                /* It is not necessary to add the nodes, edges is enough
                if let nodes = mapJson.nodes {
                    for node in nodes {
                        _ = _system.addNode(with: node.key, and: [:])
                    }
                }
                */
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
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panHandler(for:)))
        panGestureRecognizer.maximumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        arborView.addGestureRecognizer(panGestureRecognizer)

        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(ViewController.pinch(_:)))
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
    
    @objc func panHandler(for panGestureRecognizer: UIPanGestureRecognizer) {
        // move the closest node from the touch position
        let node: ATNode?
        guard let view = panGestureRecognizer.view else { return }

        let translation = panGestureRecognizer.location(in: view)
        switch panGestureRecognizer.state {
        case .began:
            node = _system.nearestNode(to: translation, within: 30.0)
            node?.isFixed = true
        default: break
        }
        
        // start the simulation
        _system.start(unpause: true)

    }
    
    /// shift the piece's center by the pan amount
    /// reset the gesture recognizer's translation to {0, 0} after applying so the next callback is a delta from the current position
    @objc func pan(_ gestureRecognizer: UIPanGestureRecognizer) {

        guard let view = gestureRecognizer.view else { return }

        switch gestureRecognizer.state {
        case .began, .changed:
            let translation = gestureRecognizer.translation(in: view)
            view.center = view.center + translation
            gestureRecognizer.setTranslation(.zero, in: view)
        default: break
        }
        
        _system.start(unpause: true)
    }

    /// scale the piece by the current scale
    /// reset the gesture recognizer's scale to 0 after applying so the next callback is a delta from the current scale
    @objc func pinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
        guard let validView = gestureRecognizer.view else { return }
        self.adjustAnchorPoint(for: gestureRecognizer)
        switch gestureRecognizer.state {
        case .began, .changed:
            gestureRecognizer.view?.transform = validView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
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
        
        // Configure simulation parameters, (take a copy, modify it, update the system when done.)
        var params = ATSystemParams()
        params.repulsion = 1000.0;
        params.stiffness = 600.0;
        params.friction  = 0.5;
        params.precision = 0.4;
        params.useBarnesHut = false
        
        _system.parameters = params
        // Setup the view bounds
        _system.viewBounds = self.arborView.bounds
        // leave some space at the bottom and top for text
        _system.viewPadding = UIEdgeInsets(top: 60.0, left: 60.0, bottom: 60.0, right: 60.0)
        // have the ‘camera’ zoom somewhat slowly as the graph unfolds
        _system.viewTweenStep = 0.2
        // set this controller as the system's delegate
        _system.delegate = self
        // DEBUG
        self.arborView.system = _system
        self.arborView.isDebugDrawing = true
        self.addGestureRecognizers(to: self.arborView)
   
        // load the map data
        self.loadMapData()

        _system.start(unpause: true)

    }
    

}

// MARK: - ATDebugRendering protocol

extension ViewController : ATDebugRendering {
    
    func redraw() {
        self.arborView.setNeedsDisplay()
    }

}

// MARK: - UIGestureRecognizerDelegate protocol

extension ViewController: UIGestureRecognizerDelegate {
    
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
