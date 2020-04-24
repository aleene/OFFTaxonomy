//
//  ATSystemState.swift
//  PSArborTouch
//
//  Created by Ed Preston on 30/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.

public struct ATSystemState {

// MARK: - public variables

    public var nodes: [ATNode] {
        _nodes.map({ $0.value })
    }
    public var edges: [ATEdge] {
        _edges.map( { $0.value })
    }
    public var adjacency: [[Int:Any]] {
        _adjacency.map( { $0.value })

    }
    public var names: [ATNode] {
        _names.map( { $0.value })

    }

// MARK: - private variables
    
    private var _nodes: [Int:ATNode] = [:]
    private var _edges: [Int:ATEdge] = [:]
    private var _adjacency: [Int:[Int:Any]] = [:]
    private var _names: [String:ATNode] = [:]
    
// MARK: - initialisers
    
    public init() { }

// MARK: - public Node functions

/** Add an ATNode to the nodes array, based on the internal unique index of the node.
 - parameters :
     - node: the node to be added

The unique key of the node will be used to identify the node in the nodes  array.

 - warning
The content of the name is NOT used, so do not rely on the name for uniqueness. Use instead Name-functions.
**/
    public mutating func addToNodes(_ node:ATNode?) {
        setNodes(with: node, for: node?.index)
    }
    
/** Add an ATNode to the nodes array with a unique key.
 - parameters :
     - node: the node to be added
     - key:  unique for the node

This might override an existing entry. If key or node are nil, nothing happens.
*/
    
    public mutating func setNodes(with node: ATNode?, for key:Int?) {

        guard node != nil else { return }
        guard let validKey = key else { return }

        _nodes[validKey] = node
    }

/** Remove an ATNode to the nodes array based on the key in the nodes array.
 - parameters :
     - key:  unique for the node
*/
    public mutating func removeNodeFromNodes(for key: Int?) {
        guard let validKey = key else { return }

        _nodes.removeValue(forKey: validKey)
    }

/** Get the ATNode from the nodes array based on the key in the nodes array.
 - parameters :
     - key:  unique for the node
*/
    public func getNodeFromNodes(for key: Int?) -> ATNode? {

        guard let validKey = key else { return nil }

        return _nodes[validKey]
    }

// MARK: - public Edge functions

    public mutating func setEdges(with edge: ATEdge?, for key: Int?) {
        //assert(key != nil, "ATSystemState.set(edge:for:) - key is nil")
        //assert(edge != nil, "ATSystemState.set(edge:for:) - edge is nil")
        guard edge != nil else { return }
        guard let validKey = key else { return }

        _edges[validKey] = edge
    }

    public mutating func removeEdgeFromEdges(for key: Int?) {
        //assert(key != nil, "ATSystemState.removeEdge(for:) - key is nil")
        guard let validKey = key else { return }

        _edges.removeValue(forKey: validKey)
    }

    public func getEdgeFromEdges(for key: Int?) -> ATEdge? {
        //assert(key != nil, "ATSystemState.getEdge(forKey:) - key is nil")
        guard let validKey = key else { return nil }

        return _edges[validKey]
    }


// MARK: - public Adjacency functions

    public mutating func setAdjacency(object: [Int:Any], for key: Int?) {
        //assert(key != nil, "ATSystemState.setAdjacency(object:forKey:) - key is nil")
        guard let validKey = key else { return }

        _adjacency[validKey] = object
    }

    public mutating func removeObjectFromAdjacency(for key: Int?) {
        //assert(key != nil, "ATSystemState.removeObjectFromAdjacency(forKey:) - key is nil")
        guard let validKey = key else { return }

        _adjacency.removeValue(forKey: validKey)
    }

    public func getAdjacency(for key: Int?) -> [Int:Any]? {
        //assert(key != nil, "ATSystemState.getAdjacency(forKey:) - key is nil")
        guard let validKey = key else { return nil }

        return _adjacency[validKey]
    }


//MARK: - public Names functions
//TODO: why is a separate store for this needed?
/**
Add an ATNode to the nodes array based on its own name.
 - parameters :
     - node: the node to be added

This might override an existing entry. If key or node are nil, nothing happens. If the name is already in the names array, it will be overwritten
**/
    public mutating func addToNames(_ node: ATNode?) {
        guard node != nil && node!.name != nil && !node!.name!.isEmpty else { return }

            _names[node!.name!] = node
        }

/**
Add an ATNode to the nodes array based on a unique name.
 - parameters :
    - node: the node to be added
    - key:  unique String to identify the node (must not be empty)

This might override an existing entry. If key or node are nil, nothing happens. If the name is already in the names array, it will be overwritten
*/
    public mutating func setNames(with node: ATNode?, for name: String?) {
        guard node != nil && name != nil && !name!.isEmpty else { return }

        _names[name!] = node
    }

/**
Remove an ATNode to the nodes array based on a unique name.
 - parameters :
    - key:  unique String to identify the node (must not be empty)

*/
    public mutating func removeNodeFromNames(for key: String?) {
        guard key != nil && !key!.isEmpty else { return }
        _names.removeValue(forKey: key!)
    }

    public func getNodeFromNames(for key: String?) -> ATNode? {
        guard key != nil && !key!.isEmpty else { return nil }

        return _names[key!]
    }

}
