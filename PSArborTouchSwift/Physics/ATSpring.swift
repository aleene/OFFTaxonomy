//
//  ATSpring.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public class ATSpring: ATEdge {

// MARK: - constants
    
    private struct Default {
        static let Stiffness = CGFloat(1000.0)
    }
    
// MARK: - public variables
    
    public var point1: ATParticle? {
        self.source as? ATParticle
    }
    public var point2: ATParticle? {
        self.target as? ATParticle
    }
    public var stiffness: CGFloat = Default.Stiffness

// MARK: - initializers
    
    override public init() {
        super.init()
    }

}
