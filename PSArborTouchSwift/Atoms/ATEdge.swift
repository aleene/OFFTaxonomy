//
//  ATEdge.swift
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

// Edges have negative indexes, Nodes have positive indexes,

public class ATEdge {
    
// MARK: - public variables
    
    public var source: ATNode? {
        _source
    }
    public var target: ATNode? {
        _target
    }
    ///Edges have negative indexes, Nodes have positive indexes,
    public var length: CGFloat = 1.0

    public var index: Int {
        _index
    }

    public var userData: [String:Any] = [:]

// MARK: - private variables
    
    private var _source: ATNode?
    private var _target: ATNode?
    private var _index: Int = 0

// MARK: - initializers
    
    public init()  {
        _index = UniqueCount.manager.nextEdgeCount
    }

    public convenience init(source: ATNode, target: ATNode, length: CGFloat) {
        self.init()
        _source = source
        _target = target
        self.length = length
    }

    public convenience init(source: ATNode, target: ATNode, userData: [String:Any]) {
        self.init()
        _source = source
        _target = target
        self.userData = userData
    }

// MARK: - public functions
    
    public func distance(to node: ATNode?) -> CGFloat? {
        guard let startPoint = source?.position else { return nil }
        guard let endPoint = target?.position else { return nil }
        guard let nodePoint = node?.position else { return nil }
        return Line(start: startPoint, end: endPoint).distance(to: nodePoint)
    }

}

// MARK: - equatable protocol

extension ATEdge: Equatable {
    public static func == (lhs: ATEdge, rhs: ATEdge) -> Bool {
        lhs.index == rhs.index
    }
}

// MARK: - hashable protocol

extension ATEdge: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}
