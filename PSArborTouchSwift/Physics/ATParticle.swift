//
//  ATParticle.h
//  PSArborTouch
//
//  Created by Ed Preston on 19/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Adapted to Swift by Arnaud Leene on 02/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics

public class ATParticle: ATNode {

// MARK: - public variables
    
    public var velocity = CGPoint.zero
    public var force = CGPoint.zero
    public var tempMass = CGFloat.zero
    public var connections: UInt = 0
    
// MARK: - initializers
    
    override public init() {
        super.init()
    }

    convenience public init(velocity:CGPoint, force: CGPoint, tempMass: CGFloat) {
        self.init()
        self.velocity = velocity
        self.force = force
        self.tempMass = tempMass
    }
        
// MARK: - public functions
    
    public func apply(force: CGPoint) {
        guard let validForce = force.divide(by: self.mass) else { return }
        self.force = self.force.add(validForce)
    }

}
