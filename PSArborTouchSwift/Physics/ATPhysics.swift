//
//  ATPhysics.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public struct ATPhysics {

// MARK: - constants
    
    private struct Constant {
        static let ForceMultiplier = CGFloat(0.5)
        // the motion limit used to stop the simulation
        static let MotionLimit = CGFloat(0.5)
    }
    
// MARK: - readonly public variables
    
    public var bhTree: ATBarnesHutTree {
        _bhTree
    }

    public var particles: [ATParticle] {
        _particles
    }

    public var springs: [ATSpring] {
        _springs
    }
    
    public var energy: ATEnergy {
        _energy
    }

// MARK: - public variables

    public var bounds: CGRect = CGRect(x: -1.0, y: -1.0, width: 2.0, height: 2.0)
    
    public var speedLimit: CGFloat = 1000.0
    public var deltaTime: CGFloat = 0.02 {
        didSet {
            self.deltaTime = abs(self.deltaTime)
        }
    }
    public var stiffness: CGFloat = 1000.0
    public var repulsion: CGFloat = 600.0
    public var friction: CGFloat = 0.3
    public var gravity: Bool = false
    public var theta: CGFloat = 0.4
    public var useBarnesHut = true

// MARK: - private variables
    
    private var _activeParticles: [ATParticle] = []
    private var _activeSprings: [ATSpring] = []
    private var _freeParticles: [ATParticle] = []
    private var _bhTree = ATBarnesHutTree()
    private var _particles: [ATParticle] = []
    private var _energy = ATEnergy()
    private var _springs: [ATSpring] = []

// MARK: - initializers
    
    init() { }

// MARK: - public functions
    
    public mutating func add(particle: ATParticle?) {
        guard let validParticle = particle else { return }

        validParticle.connections = 0
        _activeParticles.append(validParticle)
        _freeParticles.append(validParticle)
        _particles.append(validParticle)
    }

    public mutating func remove(particle: ATParticle?) {
        guard let validParticle = particle else { return }

        _particles.removeAll(where: { $0 === validParticle } )
        _activeParticles.removeAll(where: { $0 === validParticle } )
        _freeParticles.removeAll(where: { $0 === validParticle } )
    }
    
    public mutating func add(spring: ATSpring?) {
        guard let validSpring = spring else { return }

        _activeSprings.append(validSpring)
        _springs.append(validSpring)
        
        validSpring.point1?.connections += 1
        validSpring.point2?.connections += 1

        _freeParticles.removeAll(where: { $0 === validSpring.point1})
        _freeParticles.removeAll(where: { $0 === validSpring.point2})
    }

    public mutating func remove(spring: ATSpring?) {
        guard let validSpring = spring else { return }

        validSpring.point1?.connections -= 1
        validSpring.point2?.connections -= 1

        _springs.removeAll(where: { $0 === validSpring } )
        _activeSprings.removeAll(where: { $0 === validSpring } )
    }

    public mutating func isUpdated() -> Bool {
        tendParticles()
        eulerIntegrator(deltaTime: self.deltaTime)

        let motion = (self.energy.max - self.energy.mean ) / 2
        
        return motion < Constant.MotionLimit ? false : true
    }

// MARK: - private functions
    
    private mutating func tendParticles() {
        // Barnes-Hut requires accurate bounds.  If a particle has been modified from one
        // run to the next, detect it here to ensure the bounds are correct.
        let position = _activeParticles.first?.position ?? .zero
        var newBounds = CGRect.set(topLeft: position, bottomRight: position)!
        for particle in _activeParticles {
            guard let validPosition = particle.position else { continue }
            // decay down any of the temporary mass increases that were passed along
            // by using an {_m:} instead of an {m:} (which is to say via a Node having
            // its .tempMass attr set)
            
            if particle.tempMass != 0.0 {
                if abs(particle.mass - particle.tempMass) < 1.0 {
                    particle.mass = particle.tempMass;
                    particle.tempMass = 0.0;
                } else {
                    particle.mass *= 0.98;
                }
            }
            
            // zero out the velocity from one tick to the next
            particle.velocity = .zero
            
            // update the bounds
            newBounds = newBounds.include(validPosition) ?? newBounds
        }
        self.bounds = newBounds
    }
    

    private mutating func eulerIntegrator(deltaTime: CGFloat) {

        if self.repulsion > .zero {
            if self.useBarnesHut {
                applyBarnesHutRepulsion()
            } else {
                applyBruteForceRepulsion()
            }
        }
        
        if self.stiffness > 0.0 {
            applySprings()
        }
        
        applyCenterDrift()
        if self.gravity {
            applyCenterGravity()
        }
        updateVelocity(timestep: deltaTime)
        updatePosition(timestep: deltaTime)
    }
    
    private func applyBruteForceRepulsion() {
        
        for subject in _activeParticles {
            if subject.position == nil  {
                print("ATPhysics.applyBruteForceRepulsion() - subject.position is nil")
                continue
            }
            guard let subjectPosition = subject.position else { continue }
            for object in _activeParticles {
                guard subject !== object else { continue }
                if object.position == nil  {
                    print("ATPhysics.applyBruteForceRepulsion() - object.position is nil")
                }
                guard let objectPosition = object.position else { continue }
                    
                let d = subjectPosition - objectPosition
                let distance = max(1.0, d.magnitude)
                let divider = distance * distance * Constant.ForceMultiplier
                guard let direction = d.direction(radius: 1.0) else { continue }
                let multiplier = direction * self.repulsion * Constant.ForceMultiplier
                guard let force = multiplier / divider else  { continue }
                // apply force to each end point
                // (consult the cached `real' mass value if the mass is being poked to allow
                // for repositioning. the poked mass will still be used in .applyforce() so
                // all should be well)
                    
                subject.apply(force: force * object.mass)
                object.apply(force: force * -subject.mass)
            }
        }

    }

    private func applyBarnesHutRepulsion() {
        // build a barnes-hut tree...
        _bhTree.update(bounds: self.bounds, theta: self.theta)

        for particle in _activeParticles {
            _bhTree.insert(particle)
        }
        
        // ...and use it to approximate the repulsion forces
        for particle in _activeParticles {
            _bhTree.applyForces(to: particle, with: self.repulsion)
        }

    }

    private func applySprings() {

        for spring in _activeSprings {
            
            guard let validTargetPosition = spring.target?.position else { continue }
            guard let validSourcePosition = spring.source?.position else { continue }
            
            let d = validTargetPosition - validSourcePosition
            let displacement = spring.length - d.magnitude

            guard let direction = d.direction(radius: 1.0) else { continue }
            
            // apply force to each end point
            spring.point1?.apply(force: direction.multiply(by: spring.stiffness * displacement * -Constant.ForceMultiplier))
            spring.point2?.apply(force: direction.multiply(by: spring.stiffness * displacement * Constant.ForceMultiplier))
        }

    }

/// Find the centroid of all the particles in the system and shift everything, so the cloud is centered over the origin
    private func applyCenterDrift() {
        
        var numParticles: UInt = 0
        var centroid = CGPoint.zero

        for particle in _activeParticles {
            guard let validPosition = particle.position else { continue }

            centroid = centroid + validPosition
            numParticles += 1
        }
        
        guard numParticles > 0 else { return }
        
        guard let correction = centroid.divide(by: -CGFloat(numParticles)) else { return }

        for particle in _activeParticles {
            particle.apply(force: correction)
        }

    }
    
/// Attract each particle to the origin
    private func applyCenterGravity() {
        
        for particle in _activeParticles {
            guard let direction = particle.position?.multiply(by: -1.0) else { continue }
            particle.apply(force: direction.multiply(by: self.repulsion * 0.01))
        }

    }
    
    //- (void) updateVelocity:(CGFloat)timestep;
    private func updateVelocity(timestep: CGFloat) {
        assert(timestep > 0, "ATPhysics.updateVelocity(timestep:) - timestep less than zero")
        // Without advancement of time, does the simulation have meaning?
        guard timestep > 0 else { return }
        
        // translate forces to a new velocity for this particle
        for particle in _activeParticles {

            if particle.isFixed {
                particle.velocity = .zero
                particle.force = .zero
                continue
            }
            
            particle.velocity = particle.velocity + particle.force * timestep
            particle.velocity = particle.velocity.multiply(by: 1.0 - self.friction)
            particle.force = .zero
            
            // Slow down the particle if it is moving too fast.  Due to large timeStep etc.
            let speed = particle.velocity.magnitude
            
            if speed > self.speedLimit {
                particle.velocity = particle.velocity.divide(by: speed * speed) ?? .zero
            }
        }
    }

/// Move all particles according to their individual velocity.
    private mutating func updatePosition(timestep: CGFloat) {
        assert(timestep > 0.0, "ATPhysics.updatePosition(timestep:) - timestep less than zero")
        
        // Without advancement of time, does the simulation have meaning?
        guard timestep > 0 else { return }
        
        // translate velocity to a position delta
        
        var sum = CGFloat.zero
        var maximum = CGFloat.zero
        var n = CGFloat.zero
        var bottomRight = CGPoint.zero
        var topLeft = CGPoint.zero
        
        for (index, particle) in _activeParticles.enumerated() {
            // move the node to its new position
            particle.position = particle.position! + (particle.velocity * timestep)
            
            guard let position = particle.position else { continue }
            
            // keep stats to report in systemEnergy
            let speed = particle.velocity.magnitude
            let e = speed * speed
            sum += e;
            maximum = max(e, maximum)
            n += 1

            if index == 0 {
                bottomRight = position
                topLeft = position
            }
            
            // small X, small Y
            topLeft = topLeft.minimum(point: position)
            // large X, large Y
            bottomRight = bottomRight.maximum(point: position)
        }
        
        _energy.update(sum: maximum, max: maximum, count: UInt(n))
        
        self.bounds = CGRect.set(topLeft: topLeft, bottomRight: bottomRight)!
    }

}
