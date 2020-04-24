////
//  ATSystemParams.swift
//  PSArborTouch
//
//  Created by Ed Preston on 30/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.

import CoreGraphics

public struct ATSystemParams {

// MARK: - public variables
    
    public var precision = CGFloat(0.6)
    public var timemout = CGFloat(20.0)
    
// MARK: - public physics parameters
    
    public var speedLimit = CGFloat(1000.0)
    public var deltaTime = CGFloat(0.02)
    public var stiffness = CGFloat(600)
    public var repulsion = CGFloat(1000.0)
    public var friction = CGFloat(0.5)
    public var gravity = true
    
    public var useBarnesHut = true
    // used for BarnesHut
    public var theta = CGFloat(0.4)


// MARK: - initializers
    
    public init() { }
}
