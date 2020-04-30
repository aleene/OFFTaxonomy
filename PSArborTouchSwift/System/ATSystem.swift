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

    /// Find the nearest particle to a particular screen position
    public func nearestParticle(to point: CGPoint) -> ATParticle? {
        // if view bounds has been specified, presume viewPoint is in screen pixel
        // units and convert it back to the physics engine coordinates
        let translatedPoint = !self.viewBounds.isEmpty ? fromView(point: point) : point
        return self.nearestParticle(physics: translatedPoint)
    }

    /// Find the nearest node to a particular physics position
    public func nearestParticle(physics point: CGPoint) -> ATParticle? {
        var closestParticle: ATParticle?
        var closestDistance = CGFloat.greatestFiniteMagnitude
        var distance = CGFloat.zero
        
        for particle in self.state.particles {
            guard let validPosition = particle.position else { continue }
            distance = validPosition.distance(to: point)
            if distance < closestDistance {
                closestParticle = particle;
                closestDistance = distance;
            }
        }
        
        return closestParticle;
    }

    public func nearestParticle(to point: CGPoint, within screenRadius: CGFloat) -> ATParticle? {
        guard screenRadius > 0.0 else { return nil }
        
        let closestParticle = nearestParticle(to: point)
        if let position = closestParticle?.position {
            // Find the nearest particle to a particular position
            // if view bounds has been specified, presume viewPoint is in screen pixel
            // units and convert the closest node to view space for comparison

            let translatedParticlePoint = !self.viewBounds.isEmpty ? toView(point: position) : position
            if translatedParticlePoint.distance(to: point) > screenRadius {
                return nil
            }
        }
        
        return closestParticle
    }
    
    public func nearestParticle(physics point: CGPoint, within physicsRadius: CGFloat) -> ATParticle? {
        guard physicsRadius > 0.0 else { return nil }
        let closestParticle = nearestParticle(physics: point)
        if let position = closestParticle?.position {
            // check if the nearest node lies with radius
            if position.distance(to: point) > physicsRadius {
                return nil
            }
        }
        
        return closestParticle
    }
    // Graft ?
    // Merge ?
    
    public override func updateViewPort() -> Bool {
            // step the renderer's current bounding box closer to the true box containing all
            // the nodes. if _screenStep is set to 1 there will be no lag. if _screenStep is
            // set to 0 the bounding box will remain stationary after being initially set
            
            // Return NO if we dont have a screen size.
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
    public func getParticle(with name: String) -> ATParticle? {
        return self.state.getParticleFromNames(for: name)

    }

/**
Add an ATParticle with name and data.
         
 - parameters :
     - name: the String for the name. Note that names are not unique.
     - data: the data corresponding to the node
*/
    public func addParticle(with name: String, and data: [String:Any]) -> ATParticle? {

        assert(!name.isEmpty, "ATSystem.addParticle(withName:andData:) - name is empty")
        guard !name.isEmpty else { return nil }

        if let priorParticle = self.state.getParticleFromNames(for: name) {
            print("ATSystem.addParticle(withName:andData:) - Overwrote user data for a node... Be sure this is what you wanted.")
            priorParticle.userData = data;
            return priorParticle;
            
        } else {
            let particle = ATParticle(name: name, userData: data)
            particle.position = CGPoint.random(radius: 1.0)
            self.state.setNames(with: particle, for: name)
            self.state.setParticles(with: particle, for: particle.index)
            add(particle: particle)
            return particle;
        }

    }

    public func removeParticle(with name: String) {
        assert(!name.isEmpty, "ATSystem.removeNode(withName:) - name is empty")

        // remove a node and its associated edges from the graph
        if let particle = getParticle(with: name) {
            self.state.removeParticleFromParticles(for: particle.index)
            self.state.removeParticleFromNames(for: name)
            
            for spring in self.state.springs {
                if let validSourceParticle = spring.source,
                    let validTargetParticle = spring.target,
                    validSourceParticle.index == particle.index
                    || validTargetParticle.index == particle.index {
                    self.remove(spring: spring)
                }
            }
            
            remove(particle: particle)
        }

    }

// MARK: - public Edge Management functions

    public func addSpring(_ spring: ATSpring) -> ATSpring? {
        guard let validSourceName = spring.source?.name else { return nil }
        guard let validTargetName = spring.target?.name else { return nil }
        return self.addSpring(fromParticle: validSourceName, toParticle: validTargetName, with:spring.userData)
    }
    
    public func addSpring(fromParticle source: String, toParticle target: String, with data: [String:Any]) -> ATSpring? {
        // source and target should not be nil, data can be nil
        guard !source.isEmpty && !target.isEmpty else { return nil }
        
        var sourceParticle = getParticle(with: source)
        var targetParticle = getParticle(with: target)
        
        if (sourceParticle == nil) {
            // Build the source node.
            sourceParticle = addParticle(with: source, and: [:])
            // If the target already exists, put the new source near it.
            if let position = targetParticle?.position {
                sourceParticle?.position = position.nearPoint(radius: 1.0)
            }
        }
        
        if (targetParticle == nil) {
            // Build the target node
            targetParticle = addParticle(with: target, and: [:])
            if let position = sourceParticle?.position {
                // If we have to build the target node, create it close to the source node.
                targetParticle?.position = position.nearPoint(radius: 1.0)
            }
        }

        // We cant create or search for the edge if we dont have both nodes.
        guard let validSourceParticle = sourceParticle,
            let validTargetParticle = targetParticle else { return nil }
        // Create the new edge
        let spring = ATSpring(source: validSourceParticle, target: validTargetParticle, userData: data)

        // Search adjacency list
        var from: [Int : ATSpring]? = self.state.getOutboundAdjacency(for: validSourceParticle.index)
        if (from == nil) {
            // Expand the adjacency graph
            from = [:]
            self.state.setOutboundAdjacency(object: from!, for: validSourceParticle.index)
        }
        // Search adjacency list
        var toAdjacency: [Int : ATSpring]? = self.state.getInboundAdjacency(for: validTargetParticle.index)
        if (toAdjacency == nil) {
            // Expand the adjacency graph
            toAdjacency = [:]
            self.state.setInboundAdjacency(object: toAdjacency!, for: validTargetParticle.index)
        }

        guard from![validTargetParticle.index] == nil else {
            print("ATSystem.addEdge(fromNodeSource:toNodeTarget:withData:) - Overwrote user data for an edge... Be sure this is what you wanted.")
            let newTo = ATSpring()
            newTo.userData = data;
            return newTo;
        }
        
        // Store the edge
        self.state.setSprings(with: spring, for: spring.index)
        
        // Update the adjacency graph
        from![spring.index] = spring
        self.state.setOutboundAdjacency(object: from!, for:validSourceParticle.index)
        toAdjacency![spring.index] = spring
        self.state.setInboundAdjacency(object: toAdjacency!, for:validTargetParticle.index)

        // Add a new spring to represent the edge in the simulation
        add(spring: spring)
        return spring;

    }
    
    public override func remove(spring: ATSpring?) {
        guard let validSpring = spring else { return }
        self.state.removeSpringFromSprings(for: validSpring.index)
        guard let sourceIndex = validSpring.source?.index else { return }
        guard let targetIndex = validSpring.target?.index else { return }
        
        var from = self.state.getOutboundAdjacency(for: sourceIndex)
        if (from != nil) {
            from?.removeValue(forKey: targetIndex)
        }
        remove(spring: validSpring)
    }

    public func getSprings(fromParticle source: String, toParticle target: String) -> Set<ATSpring> {
        guard let sourceParticle = getParticle(with: source) else { return [] }
        guard let targetParticle = getParticle(with: target) else { return [] }
        guard let from = self.state.getOutboundAdjacency(for: sourceParticle.index) else { return [] }
        guard let to = from[targetParticle.index] else { return [] }
        
        let toSet: Set<ATSpring> = Set.init([to])
        return toSet
    }

    public func getSprings(fromParticleWith name: String) -> Set<ATSpring> {
        guard !name.isEmpty else { return [] }
        guard let aParticle = getParticle(with: name) else { return  [] }
        
        var springs: [ATSpring] = []
        for element in self.state.outboundAdjacency[aParticle.index] {
            springs.append(element.value)
        }
        let newSet: Set<ATSpring> = Set.init(springs)
        return newSet

    }

    public func getSprings(toParticleWith name: String) -> Set<ATSpring> {
        guard !name.isEmpty else { return [] }
        guard let aParticle = getParticle(with: name) else { return [] }

        var particleSprings: Set<ATSpring> = []
        for spring in self.state.springs {
            if spring.target != nil,
                spring.target! === aParticle {
                particleSprings.insert(spring)
            }
        }
        return particleSprings;
    }
    
    public func addTaxonomy(particles: [ATParticle], springs: [ATSpring]) {
        particles.forEach({_ = addParticle(with: $0.name!, and: $0.userData)  })
        springs.forEach({ _ = addSpring($0) })
    }
/**
Is the node with a set distance of a particle?
    
- parameters:
     - particle: the ATParticle that is interrogated
     - focus: the focus node
     - distance: the focus distance (steps), 0 is the particle itself.
*/
    public func determineFocusParticleIndices(around focus: ATParticle?, within distance: Int) -> Set<Int> {
        guard let validFocusIndex = focus?.index else { return [] }
        let newDistance = abs(distance)
        var indices: Set<Int> = [validFocusIndex]
        indices = indices.union(checkOutboundAdjacencies(for: validFocusIndex, within: newDistance - 1))
        indices = indices.union(checkInboundAdjacencies(for: validFocusIndex, within: newDistance - 1))
        return indices
    }
    
    // check all the targets around a node
    private func checkOutboundAdjacencies(for focusIndex: Int, within distance: Int) -> Set<Int> {
        // Is there more to check?
        if distance < 0 { return [] }
        var indices: Set<Int> = []
        guard let outBoundAdjacencies = self.state.getOutboundAdjacency(for: focusIndex) else { return [] }
        // The adjacency defines the ATSpring's connected to the focus particle
        for adjacency in outBoundAdjacencies {
            if let targetIndex = adjacency.value.target?.index {
                indices.insert(targetIndex)
                let newIndices = checkOutboundAdjacencies(for: targetIndex, within: distance - 1)
                indices = indices.union(newIndices)
            }
        }
        return indices
    }
    // check all the sources around a node
    private func checkInboundAdjacencies(for focusIndex: Int, within distance: Int) -> Set<Int> {
        // Is there more to check?
        if distance < 0 { return [] }
        var indices: Set<Int> = []
        guard let inboundAdjacencies = self.state.getInboundAdjacency(for: focusIndex) else { return [] }
        // The adjacency defines the ATSpring's connected to the focus particle
        for adjacency in inboundAdjacencies {
            if let sourceIndex = adjacency.value.source?.index {
                indices.insert(sourceIndex)
                let newIndices = checkInboundAdjacencies(for: sourceIndex, within: distance - 1)
                indices = indices.union(newIndices)
            }
        }
        return indices
    }

}
