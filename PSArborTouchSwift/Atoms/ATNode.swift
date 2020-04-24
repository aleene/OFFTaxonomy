//
//  ATNode.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation
import CoreGraphics

public class ATNode {
    
// MARK: - public variables
    
    // TODO: should we put name into the userData?
    public var name: String? {
        _name
    }
    public var mass = CGFloat(1.0)
    public var position: CGPoint? = CGPoint.zero
    public var isFixed: Bool = false
    /// Nodes have positive indexes, Edges have negative indexes
    public var index: Int {
        _index
    }
    public var userData: [String:Any] = [:]
    
// MARK: - private variables
    
    private var _name: String = ""
    private var _index: Int = 0

// MARK: - initializers
    
    public init() {
        _index = UniqueCount.manager.nextNodeCount
    }
    
    convenience public init(name: String, mass: CGFloat, position: CGPoint, fixed:Bool) {
        self.init()
        _name = name
        self.mass = mass
        self.position = position
        self.isFixed = fixed

    }

    convenience public init(name: String, userData data: [String:Any]) {
// TODO: This method should be reviewed. Does not produce a useable object.
    // Is this a general user data store or keyed archiving style object creation?
        self.init()
        _name = name
        self.userData = data
    }
    
}

// MARK: - equatable protocol

extension ATNode: Equatable {

    public static func == (lhs: ATNode, rhs: ATNode) -> Bool {
        lhs.index == rhs.index
    }
}

// MARK: - hashable protocol

extension ATNode: Hashable {

// support hashable protocol
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }

}

