//
//  ATSystem.h
//  PSArborTouch
//
//  Created by Ed Preston on 19/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.

import CoreGraphics
import UIKit

public enum ATViewConversion {
    case stretch
    case scale
}

public class ATSystem: ATKernel {

// MARK: - constants
    
    private struct Constant {
        static let ViewTweenStep = CGFloat(0.1)
    }
    
// MARK: - initializers

    override public init() {
        super.init()
    }
    
    convenience init(state: ATSystemState, parameters: ATSystemParams) {
        self.init()
        self.state = state
        self.parameters = parameters
    }

// MARK: - public variables
    
    public var state = ATSystemState()
    
    public var parameters: ATSystemParams? {
        didSet {
            guard parameters != nil else { return }
//TODO: This can also be put in a super.init?
            self.setupPhysics(speedLimit: parameters!.speedLimit,
                              deltaTime: parameters!.deltaTime,
                              stiffness: parameters!.stiffness,
                              repulsion: parameters!.repulsion,
                              friction: parameters!.friction,
                              gravity: parameters!.gravity,
                              useBarnesHut: parameters!.useBarnesHut,
                              theta: parameters!.theta)
        }
    }

    public var tweenBoundsCurrent: CGRect {
        _tweenBoundsCurrent
    }
    public var tweenBoundsTarget: CGRect {
        _tweenBoundsTarget
    }
    
    public var viewBounds = CGRect.zero {
        didSet {
            _ = updateViewPort()
        }
    }
    public var viewPadding = UIEdgeInsets.zero
    public var viewTweenStep = Constant.ViewTweenStep
    public var viewMode: ATViewConversion = .scale

// MARK: - private variables
        
    private var _tweenBoundsCurrent = CGRect.zero
    private var _tweenBoundsTarget = CGRect.zero

    /// Adjusting the translation bounds defines what coordinate system is being used as the camera.
    private var _translationBounds: CGRect {
        self.simulationBounds;
    }
    
// MARK: - public Viewport functions

    public func toView(rect physicsRect: CGRect) -> CGRect {
        return CGRect(origin: toView(point: physicsRect.origin),
                      size: toView(size: physicsRect.size))
    }
    
    /// Return the size in the physics coordinate system if we dont have a screen size or current viewport bounds.
    public func toView(size physicsSize: CGSize) -> CGSize {
        return self.viewBounds.isEmpty
            || self.tweenBoundsCurrent.isEmpty ?
                physicsSize :
                physicsSize.toView(viewSize: viewBounds.size.pad(with:self.viewPadding),
                               screenSize: _translationBounds.size,
                                viewMode: .scale)
    }

    /// Return the point in the physics coordinate system if we dont have a screen size or current viewport bounds.
    public func toView(point physicsPoint: CGPoint) -> CGPoint {
        if self.viewBounds.isEmpty
            || self.tweenBoundsCurrent.isEmpty {
            return physicsPoint
        }
                
        let adjustedScreenSize = self.viewBounds.size.pad(with: self.viewPadding)
        
        
        var newPoint = CGPoint.zero
        let topRightPadding = CGPoint(x: self.viewPadding.right, y: self.viewPadding.top)

        switch self.viewMode {
        case . scale:
            let uniformScale = min(adjustedScreenSize.width, adjustedScreenSize.height)
            newPoint = (newPoint * uniformScale) + topRightPadding
            // center
            newPoint = newPoint + adjustedScreenSize.reduce(by:uniformScale)
            newPoint = newPoint * 0.5
        case .stretch:
            let scale = physicsPoint.scaleInRect(_translationBounds)!
            newPoint = newPoint * scale + topRightPadding
        }
        
        return newPoint
    }
    
    /// Return the point in the screen coordinate system if we dont have a screen size.
    public func fromView(point: CGPoint) -> CGPoint {
        if self.viewBounds.isEmpty
            || self.tweenBoundsCurrent.isEmpty {
            return point
        }
        
        let toBounds = _translationBounds        
        let adjustedScreenSize = self.viewBounds.size.pad(with: self.viewPadding)
        
        switch self.viewMode {
        case .scale:
            let uniform = min(adjustedScreenSize.width, adjustedScreenSize.height)
            let newSize = adjustedScreenSize - uniform
            guard let scale = (point - newSize.halved.asCGPoint - self.viewPadding.topRight) / uniform else { return .zero }
            return scale * toBounds.size.asCGPoint + toBounds.origin
        case .stretch:
            guard let scale = (point - self.viewPadding.topRight) / adjustedScreenSize else { return .zero }
            return scale * toBounds.size.asCGPoint + toBounds.origin
        }
    }

    /// Find the nearest node to a particular position
    public func nearestNode(to point: CGPoint) -> ATNode? {
        // if view bounds has been specified, presume viewPoint is in screen pixel
        // units and convert it back to the physics engine coordinates
        let translatedPoint = !self.viewBounds.isEmpty ? fromView(point: point) : point
        
        var closestNode: ATNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude
        var distance = CGFloat.zero
        
        for node in self.state.nodes {
            guard let validPosition = node.position else { continue }
            distance = validPosition.distance(to: translatedPoint)
            if distance < closestDistance {
                closestNode = node;
                closestDistance = distance;
            }
        }
        
        return closestNode;
    }

    public func nearestNode(to point: CGPoint, within radius: CGFloat) -> ATNode? {
        //assert(radius > 0.0, "ATSystem.nearestNode(toPoint:withinRadius:) - radius less then zero")
        // or use nearestNodeToPoint instead.
        guard radius > 0.0 else { return nil }
        
        let closestNode = nearestNode(to: point)
        if let position = closestNode?.position {
            // Find the nearest node to a particular position
            // if view bounds has been specified, presume viewPoint is in screen pixel
            // units and convert the closest node to view space for comparison

            let translatedNodePoint = !self.viewBounds.isEmpty ? toView(point: position) : position
            if translatedNodePoint.distance(to: point) > radius {
                return nil
            }
        }
        
        return closestNode

    }
    // Graft ?
    // Merge ?
    
    public override func updateViewPort() -> Bool {
            // step the renderer's current bounding box closer to the true box containing all
            // the nodes. if _screenStep is set to 1 there will be no lag. if _screenStep is
            // set to 0 the bounding box will remain stationary after being initially set
            
            // Return NO if we dont have a screen size.
            //assert(self.viewBounds.size.width > 0, "ATSystem.updateViewPort() - viewBounds.width is zero")
            //assert(self.viewBounds.size.height > 0, "ATSystem.updateViewPort() - viewBounds.height is zero")
            guard self.viewBounds.size.width > 0
                && self.viewBounds.size.height > 0 else { return false }
            // Ensure the view bounds rect has a minimum size
            _tweenBoundsTarget = self.simulationBounds.ensureMinimumDimension(4.0)!
            
            // Configure the current viewport bounds
            if _tweenBoundsCurrent.isEmpty {
                if self.state.names.isEmpty { return false }
                _tweenBoundsCurrent = _tweenBoundsTarget;
                return true
            }
            
            // If we are not tweening, then no need to calculate. Avoid endless viewport update.
            if viewTweenStep <= 0.0 { return false }
            
            // Move the current viewport bounds closer to the true box containing all the nodes.
            let newBounds = _tweenBoundsCurrent.tweenTo(rect:_tweenBoundsTarget, with: viewTweenStep)
            
            // calculate the difference
        let newX = _tweenBoundsCurrent.width - newBounds.width
        let newY = _tweenBoundsCurrent.height - newBounds.height
        let sizeDiff = CGPoint(x: newX, y: newY)
        let diff = CGPoint(x: _tweenBoundsCurrent.origin.distance(to: newBounds.origin),
                               y: sizeDiff.magnitude )
        // return YES if we're still approaching the target, NO if we're ‘close enough’
        if diff.x * viewBounds.width > 1.0
            || diff.y * viewBounds.height > 1.0 {
            _tweenBoundsCurrent = newBounds;
            return true
        } else {
            return false
        }
    }

// MARK: - public Node Management functions

/**
Retrieve a node based on its name.
     
- parameters :
     - name: the String for the name. Note that names are not unique.
*/
    public func getNode(with name: String) -> ATNode? {
        return self.state.getNodeFromNames(for: name)

    }

/**
Add an ATNode with name and data.
         
 - parameters :
     - name: the String for the name. Note that names are not unique.
     - data: the data corresponding to the node
*/
    public func addNode(with name: String, and data: [String:Any]) -> ATNode? {

        assert(!name.isEmpty, "ATSystem.addNode(withName:andData:) - name is empty")
        guard !name.isEmpty else { return nil }

        if let priorNode = self.state.getNodeFromNames(for: name) {
            print("ATSystem.addNode(withName:andData:) - Overwrote user data for a node... Be sure this is what you wanted.")
            priorNode.userData = data;
            return priorNode;
            
        } else {
            let node = ATParticle(name: name, userData: data)
            node.position = CGPoint.random(radius: 1.0)
            self.state.setNames(with: node, for: name)
            self.state.setNodes(with: node, for: node.index)
            add(particle: node)
            return node;
        }

    }

    public func removeNode(with name: String) {
        assert(!name.isEmpty, "ATSystem.removeNode(withName:) - name is empty")

        // remove a node and its associated edges from the graph
        if let node = getNode(with: name) {
            self.state.removeNodeFromNodes(for: node.index)
            self.state.removeNodeFromNames(for: name)
            
            for edge in self.state.edges {
                if let validSourceNode = edge.source,
                    let validTargetNode = edge.target,
                    validSourceNode.index == node.index
                    || validTargetNode.index == node.index {
                    self.remove(edge: edge)
                }
            }
            
            remove(particle: node as? ATParticle)
        }

    }

// MARK: - public Edge Management functions

    public func addEdge(fromNode source: String, toNode target: String, with data: [String:String]) -> ATEdge? {
        //assert(!source.isEmpty, "ATSystem.addEdge(fromNode:toNode:with:) - source is empty")
        //assert(!target.isEmpty, "ATSystem.addEdge(fromNodeSource:toNodeTarget:withData:) - target is empty")

        // source and target should not be nil, data can be nil
        guard !source.isEmpty && !target.isEmpty else { return nil }
        
        var sourceNode = getNode(with: source)
        var targetNode = getNode(with: target)
        
        if (sourceNode == nil) {
            // Build the source node.
            sourceNode = addNode(with: source, and: [:])
            // If the target already exists, put the new source near it.
            if let position = targetNode?.position {
                sourceNode?.position = position.nearPoint(radius: 1.0)
            }
        }
        
        if (targetNode == nil) {
            // Build the target node
            targetNode = addNode(with: target, and: [:])
            if let position = sourceNode?.position {
                // If we have to build the target node, create it close to the source node.
                targetNode?.position = position.nearPoint(radius: 1.0)
            }
        }
        
        // We cant create or search for the edge if we dont have both nodes.
        guard let validSourceNode = sourceNode,
            let validTargetNode = targetNode else { return nil }
        
        // Search adjacency list
        var from: [Int : Any]? = self.state.getAdjacency(for: validSourceNode.index)
        if (from == nil) {
            // Expand the adjacency graph
            from = [:]
            self.state.setAdjacency(object: from!, for: validSourceNode.index)
        }

        guard from![validTargetNode.index] as? ATEdge == nil else {
            print("ATSystem.addEdge(fromNodeSource:toNodeTarget:withData:) - Overwrote user data for an edge... Be sure this is what you wanted.")
            let newTo = ATEdge()
            newTo.userData = data;
            return newTo;
        }
        
        // Create the new edge
        let edge = ATSpring(source: validSourceNode, target: validTargetNode, userData: data)
        // Store the edge
        self.state.setEdges(with: edge, for: edge.index)
        
        // Update the adjacency graph
        from![validTargetNode.index] = edge
        
        // Add a new spring to represent the edge in the simulation
        add(spring: edge)
        return edge;

    }
    
    public func remove(edge: ATEdge?) {
        //assert(edge != nil, "ATSystem.remove(edge:) - edge is nil")
        //assert(validEdge.source?.index != nil, "ATSystem.addEdge(fromNode:toNode:with:) - validEdge.source?.index is nil")
        guard let validEdge = edge else { return }
        self.state.removeEdgeFromEdges(for: validEdge.index)
        guard let sourceIndex = validEdge.source?.index else { return }
        //assert(validEdge.target?.index != nil, "ATSystem.addEdge(fromNode:toNode:with:) - validEdge.target?.index is nil")
        guard let targetIndex = validEdge.target?.index else { return }
        
        var from = self.state.getAdjacency(for: sourceIndex)
        if (from != nil) {
            from?.removeValue(forKey: targetIndex)
        }
        remove(spring: validEdge as? ATSpring)
    }

    public func getEdges(fromNode source: String, toNode target: String) -> Set<ATEdge> {
        //assert(!source.isEmpty, "ATSystem.getEdges(fromNodeSource:toNodeTarget:) - source is empty")
        //assert(!target.isEmpty, "ATSystem.getEdges(fromNodeSource:toNodeTarget:) - target is empty")
        //assert(self.state.getAdjacency(for: sourceNode.index) != nil, "ATSystem.addEdge(fromNode:toNode:with:) - self.state.getAdjacency(for: sourceNode.index) is nil")
        //assert(from[targetNode.index] as? ATEdge != nil, "ATSystem.addEdge(fromNode:toNode:with:) - from[targetNode.index] as? ATEdge is nil")
        guard let sourceNode = getNode(with: source) else { return [] }
        guard let targetNode = getNode(with: target) else { return [] }
        guard let from = self.state.getAdjacency(for: sourceNode.index) else { return [] }
        guard let to = from[targetNode.index] as? ATEdge else { return [] }
        
        let toSet: Set<ATEdge> = Set.init([to])
        return toSet
    }

    public func getEdges(fromNodeWith name: String) -> Set<ATEdge> {
        //assert(!name.isEmpty, "ATSystem.getEdges(fromNodeWith:) - node is nil")
        //assert(getNode(with: name) != nil, "ATSystem.getEdges(fromNodeWith:) - getNode(for: name) is nil")
        guard !name.isEmpty else { return [] }
        guard let aNode = getNode(with: name) else { return  [] }
        
        var edges: [ATEdge] = []
        for element in self.state.adjacency[aNode.index] {
            if let validElement = element.value as? ATEdge {
                edges.append(validElement)
            }
        }
        let newSet: Set<ATEdge> = Set.init(edges)
        return newSet

    }

    public func getEdges(toNodeWith name: String) -> Set<ATEdge> {
        //assert(!name.isEmpty, "ATSystem.getEdges(toNodeWith:) - node is nil")
        //assert(getNode(with: name) != nil, "ATSystem.getEdges(toNodeWith:) - getNode(for: name) is nil")
        guard !name.isEmpty else { return [] }
        guard let aNode = getNode(with: name) else { return [] }

        var nodeEdges: Set<ATEdge> = []
        for edge in self.state.edges {
            if edge.target != nil,
                edge.target! === aNode {
                nodeEdges.insert(edge)
            }
        }
        return nodeEdges;
    }

}
