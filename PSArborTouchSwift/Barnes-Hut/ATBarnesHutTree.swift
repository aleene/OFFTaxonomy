//
//  ATBarnesHutTree.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public class ATBarnesHutTree {

// MARK: - public variables
    
    public var root: ATBarnesHutBranch {
        _root
    }
    public var bounds : CGRect {
        _bounds
    }
    public var theta: CGFloat {
        _theta
    }

// MARK: - private variables
    
    private var _root: ATBarnesHutBranch = ATBarnesHutBranch()
    private var _bounds = CGRect.zero
    private var _theta: CGFloat = 0.4
    
    private var _branches: [ATBarnesHutBranch] = []
    private var _branchCounter: UInt = 0

// MARK: - initializers
    
    public init() { }
    
// MARK: - public functions
    
    ///  update and reset variables
    public func update(bounds: CGRect, theta: CGFloat) {
        _bounds = bounds
        _theta = theta
        _branchCounter = 0
        _root = self.dequeueBranch()
        _root.bounds = bounds
    }
    
    /// add a particle to the tree, starting at the current _root and working down
    public func insert(_ newParticle: ATParticle) {
        
        var node = root
        var queue: [ATParticle] = []
        
        // Add particle to the end of the queue
        queue.append(newParticle)
        
        while queue.count != 0 {
            // dequeue
            let currentParticle = queue[0]
            queue.remove(at: 0)
            
            let currentParticleMass = currentParticle.mass
            guard let currentParticleQuadrant = node.quadrant(containing: currentParticle) else { continue }
            switch node.quadrantObject[currentParticleQuadrant] {
                
            case .tree(let quadrantTree):
                // slot contains a branch node, keep iterating with the branch
                // as our new root
                
                node.mass += currentParticleMass
                if let position = currentParticle.position?.multiply(by: currentParticleMass) {
                    node.position = node.position + position
                    node = quadrantTree
                }
                // add the particle to the front of the queue
                queue.insert(currentParticle, at: 0)
                
            case .particle(let quadrantParticle):
                // slot contains a particle, create a new branch and recurse with
                // both points in the queue now
                
                if node.bounds ~= CGRect.zero {
                    print("ATBarnesHutTree:insert(_:) - Bounds width or height should not be zero?")
                }

                // CHECK IF POINT IN RECT TO AVOID RECURSIVELY MAKING THE RECT INFINITELY
                // SMALLER FOR SOME POINTS OUT OF BOUNDS.
                
                // replace the previously particle-occupied quad with a new internal branch node
                let oldParticle = quadrantParticle
                let newBranch = self.dequeueBranch()
                node.quadrantObject[currentParticleQuadrant] = .tree(newBranch)
                
                let branch_size =  node.bounds.halved
                var branch_origin = node.bounds.origin
                
                branch_origin.x += currentParticleQuadrant.isLeft ? branch_size.width : .zero
                branch_origin.y += currentParticleQuadrant.isBottom ? branch_size.height : .zero
                newBranch.bounds = CGRect(origin: branch_origin, size: branch_size)

                node.mass = currentParticleMass
                node.position = currentParticle.position?.multiply(by: currentParticleMass) ?? .zero

                node = newBranch
                
                if let oldPosition = oldParticle.position,
                    let validPosition = currentParticle.position,
                    ( oldPosition == validPosition ) {
                    // prevent infinite bisection in the case where two particles
                    // have identical coordinates by jostling one of them slightly
                    
                    let spread = branch_size.scale(by: 0.08)
                    
                    // create a random point with a square of +/- 0.08
                    let randomPosition = CGPoint.random(radius: 1.0)! *  spread.asCGPoint
                    // center this random position around the old position
                    let centeredRandomPosition = oldPosition - spread.halved.asCGPoint + randomPosition
                    // determine the largest position
                    let maximumPosition = branch_origin.maximum(point: centeredRandomPosition)
                    // and then the smallest
                    let minimumPosition = branch_origin.minimum(point: maximumPosition)
                                        
                    oldParticle.position = minimumPosition
                }
                
                // keep iterating but now having to place both the current particle and the
                // one we just replaced with the branch node
                
                // Add old particle to the end of the array
                queue.append(oldParticle)
                // Add new particle to the start of the array
                queue.insert(currentParticle, at: 0)

            default:
                // slot is empty, just drop this node in and update the mass/c.o.m.
                node.mass += currentParticleMass

                if let position = currentParticle.position?.multiply(by: currentParticleMass) {
                    node.position = node.position + position
                } else {
                    node.position = .zero
                }
                node.quadrantObject[currentParticleQuadrant] = .particle(currentParticle)
            }
        }

    }
    
/// Find all particles/branch nodes this particle interacts with and apply the specified repulsion to the particle
    public func applyForces(to particle: ATParticle, with repulsion: CGFloat) {
        // find all particles/branch nodes this particle interacts with and apply
        // the specified repulsion to the particle
        guard let particlePosition = particle.position else { return }
        var queue: [ATBarnesHutNode] = []
        queue.append(.tree(self.root))
        
        while queue.count != 0 {
            // dequeue
            let node = queue[0]
            queue.remove(at: 0)

            switch node {
            case .particle(let objectParticle):
                if objectParticle == particle { break }
                if let nodePosition = objectParticle.position {
                // this is a particle leafnode, so just apply the force directly
                    let d = particlePosition - nodePosition
                    let distance = max(1.0, d.magnitude)
                    guard let direction = d.direction(radius: 1.0) else { continue }
                    guard let force = direction.multiply(by: repulsion * objectParticle.mass).divide(by: distance * distance) else { continue }
                    particle.apply(force:force)
                }
                
            case .tree(let objectTree):
            // it's a branch node so decide if it's cluster-y and distant enough
            // to summarize as a single point. if it's too complex, open it and deal
            // with its quadrants in turn
                guard let position = objectTree.position.divide(by: objectTree.mass) else { continue }
                let newPosition = particlePosition - position

                if ( objectTree.bounds.averageDistance / newPosition.magnitude ) > theta {
                    // open the quad and recurse
                    queue.append(contentsOf: objectTree.allQuadrantObjects)
                } else {
                    // treat the quad as a single body
                    guard let position = objectTree.position.divide(by: objectTree.mass) else { break }
                    let d = particlePosition.subtract(position)
                    let distance = max(1.0, d.magnitude)
                    guard let direction = d.direction(radius: 1.0) else { continue }
                    guard let force = direction.multiply(by:repulsion * objectTree.mass)
                                    .divide(by: distance * distance) else { continue }

                    particle.apply(force: force)
                }
                default: break
            }
        }

    }

// MARK: - private functions
    
    private func dequeueBranch() -> ATBarnesHutBranch {
        // Recycle the tree nodes between iterations, nodes are owned by the branches array
        var branch = ATBarnesHutBranch()
        
        if _branches.count == 0
        || _branchCounter > _branches.count - 1 {
            _branches.append(branch)
            
        } else {
            branch = _branches[Int(_branchCounter)];
            branch.reset()
        }
            
        _branchCounter += 1
            
        return branch
    }

}
