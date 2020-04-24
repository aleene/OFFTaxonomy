//
//  ATBarnesHutBranch.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public final class ATBarnesHutBranch {

// MARK: - public variables
    
    public var bounds = CGRect.zero
    public var mass = CGFloat.zero
    public var position = CGPoint.zero

    public var quadrantObject: [CGSize.Quadrant:ATBarnesHutNode] = [.topLeft:.undefined,
                                                     .topRight:.undefined,
                                                     .bottomLeft: .undefined,
                                                     .bottomRight:.undefined]
// MARK: - initializers
    
    public init() { }

    /// make an instance of this class by setting some public variables
    convenience public init(bounds: CGRect, mass: CGFloat, position: CGPoint) {
        self.init()
        self.bounds = bounds
        self.mass = mass
        self.position = position
    }

// MARK: - public functions
    
    /// reset all public variables to zero or undefined
    public func reset() {
        quadrantObject = [.topLeft:.undefined,
                          .topRight:.undefined,
                          .bottomLeft: .undefined,
                          .bottomRight:.undefined]
        self.bounds = .zero
        self.mass = .zero
        self.position = .zero
    }

    /// returns the quadrant in which the particle is located
    public func quadrant(containing particle: ATParticle) -> CGSize.Quadrant? {
        guard let validParticlePosition = particle.position else { return nil }
        return self.bounds.quadrant(containing: validParticlePosition)

    }
    
    /// returns the object in the quadrant in which the particle is located
    public func quadrantObjectFor(_ particle: ATParticle) -> ATBarnesHutNode? {
        guard let quadrant = quadrant(containing: particle) else { return nil }
        return quadrantObject[quadrant]!
    }

    /// Returns all the existing Objects (particles and/or branches) for all quadrants
    public var allQuadrantObjects: [ATBarnesHutNode] {
        quadrantObject.map({ $0.value })
    }

    /// Returns all the existing ATBarnesHutBranch'es for all quadrants
    public var allQuadrantBranches: [ATBarnesHutBranch] {
        let filter = quadrantObject.filter({ $0.value ~= .tree(ATBarnesHutBranch()) })
        return filter.compactMap({
            switch $0.value {
            case .tree(let value):
                return value
            default:
                return nil
            }
        })
    }

}

// MARK: - Equatable protocol

extension ATBarnesHutBranch : Equatable {
    
    /// Function to make the class equatable
    public static func ==(lhs: ATBarnesHutBranch, rhs: ATBarnesHutBranch) -> Bool {
        return lhs.bounds == rhs.bounds
            && lhs.mass == rhs.mass
            && lhs.position == rhs.position
            && lhs.quadrantObject[.topLeft] == rhs.quadrantObject[.topLeft]
            && lhs.quadrantObject[.topRight] == rhs.quadrantObject[.topRight]
            && lhs.quadrantObject[.bottomLeft] == rhs.quadrantObject[.bottomLeft]
            && lhs.quadrantObject[.bottomRight] == rhs.quadrantObject[.bottomRight]
    }

}
