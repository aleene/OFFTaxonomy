//
//  ATEnergy.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public struct ATEnergy {
    
// MARK: - public variables
    
    public var sum = CGFloat.zero
    public var max = CGFloat.zero
    public var mean = CGFloat.zero
    public var count: UInt = 0
    
// MARK: - initializers
    
    public init() { }
    
    public init(sum: CGFloat, max:CGFloat, mean: CGFloat, count: UInt) {
        self.sum = sum
        self.max = max
        self.mean = mean
        self.count = count
    }
    
// MARK: - public functions
    
    public mutating func update(sum: CGFloat, max: CGFloat, count: UInt) {
        self.sum = sum
        self.max = max
        self.count = count
        self.mean = self.sum / CGFloat(self.count)
    }

}
