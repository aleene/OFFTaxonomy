//
//  UniqueCount.swift
//  SystemRig
//
//  Created by arnaud on 05/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation

public class UniqueCount {
    
    // This class is implemented as a singleton
    // It allows to have a unique id for each Edge and Node
    // Nodes have positive indexes, Edges have negative indexes

// MARK: - constants
    
    fileprivate struct Constants {
        static let Base = 0
    }

    public static let manager = UniqueCount()
    
// MARK: - public variables
    
    /// A unique counter for Edge instances. These are negative.
    public var nextEdgeCount: Int {
        edgeCount -= 1
        return edgeCount
    }

    public var nextNodeCount: Int {
        nodeCount += 1
        return nodeCount
    }

// MARK: - private variables
    
    private var edgeCount = Constants.Base

    private var nodeCount = Constants.Base

    
// MARK: - public functions
    
    /// Reset the counters, should only be used for testing
    public func reset() {
        edgeCount = Constants.Base
        nodeCount = Constants.Base
    }

}

