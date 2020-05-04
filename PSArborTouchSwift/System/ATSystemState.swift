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

    public var particles: [ATParticle] {
        _particles.map({ $0.value })
    }
    public var springs: [ATSpring] {
        _springs.map( { $0.value })
    }
    public var outboundAdjacency: [[Int:ATSpring]] {
        _outboundAdjacency.map( { $0.value })
    }
    public var inboundAdjacency: [[Int:ATSpring]] {
        _inboundAdjacency.map( { $0.value })
    }
    public var names: [ATParticle] {
        _names.map( { $0.value })

    }

// MARK: - private variables
    
    private var _particles: [Int:ATParticle] = [:]
    private var _springs: [Int:ATSpring] = [:]
    private var _outboundAdjacency: [Int:[Int:ATSpring]] = [:]
    private var _inboundAdjacency: [Int:[Int:ATSpring]] = [:]
    private var _names: [String:ATParticle] = [:]
    
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
    public mutating func addToParticles(_ particle:ATParticle?) {
        setParticles(with: particle, for: particle?.index)
    }
    
/** Add an ATParticle to the nodes array with a unique key.
 - parameters :
     - node: the node to be added
     - key:  unique for the node

This might override an existing entry. If key or node are nil, nothing happens.
*/
    
    public mutating func setParticles(with particle: ATParticle?, for key:Int?) {

        guard particle != nil else { return }
        guard let validKey = key else { return }

        _particles[validKey] = particle
    }

/** Remove an ATParticle to the nodes array based on the key in the nodes array.
 - parameters :
     - key:  unique for the node
*/
    public mutating func removeParticleFromParticles(for key: Int?) {
        guard let validKey = key else { return }

        _particles.removeValue(forKey: validKey)
    }

/** Get the ATParticle from the nodes array based on the key in the nodes array.
 - parameters :
     - key:  unique for the node
*/
    public func getParticleFromParticles(for key: Int?) -> ATParticle? {

        guard let validKey = key else { return nil }

        return _particles[validKey]
    }

// MARK: - public Edge functions

    public mutating func setSprings(with spring: ATSpring?, for key: Int?) {
        guard spring != nil else { return }
        guard let validKey = key else { return }

        _springs[validKey] = spring
    }

    public mutating func removeSpringFromSprings(for key: Int?) {
        guard let validKey = key else { return }

        _springs.removeValue(forKey: validKey)
    }

    public func getSpringFromSprings(for key: Int?) -> ATSpring? {
        guard let validKey = key else { return nil }

        return _springs[validKey]
    }


// MARK: - public Adjacency functions

/**
Adjacency describes the connected edges to a node

- parameters:
     - object: an array of edge indices and corresponding edges connected to this adjacency
     - key: the index of the node corresponding to the adjacency
*/
    public mutating func setOutboundAdjacency(object: [Int:ATSpring], for key: Int?) {
        guard let validKey = key else { return }

        _outboundAdjacency[validKey] = object
    }

    public mutating func removeObjectFromOutboundAdjacency(for key: Int?) {
        guard let validKey = key else { return }

        _outboundAdjacency.removeValue(forKey: validKey)
    }

    public func getOutboundAdjacency(for key: Int?) -> [Int:ATSpring]? {
        guard let validKey = key else { return nil }

        return _outboundAdjacency[validKey]
    }

    public mutating func setInboundAdjacency(object: [Int:ATSpring], for key: Int?) {
        guard let validKey = key else { return }

        _inboundAdjacency[validKey] = object
    }

    public mutating func removeObjectFromInboundAdjacency(for key: Int?) {
        guard let validKey = key else { return }

        _inboundAdjacency.removeValue(forKey: validKey)
    }

    public func getInboundAdjacency(for key: Int?) -> [Int:ATSpring]? {
        guard let validKey = key else { return nil }

        return _inboundAdjacency[validKey]
    }

//MARK: - public Names functions
//TODO: why is a separate store for this needed?
/**
Add an ATParticle to the nodes array based on its own name.
 - parameters :
     - node: the node to be added

This might override an existing entry. If key or node are nil, nothing happens. If the name is already in the names array, it will be overwritten
**/
    public mutating func addToNames(_ particle: ATParticle?) {
        guard particle != nil
            && particle!.name != nil
            && !particle!.name!.isEmpty else { return }

            _names[particle!.name!] = particle
        }

/**
Add an ATParticle to the nodes array based on a unique name.
 - parameters :
    - node: the node to be added
    - key:  unique String to identify the node (must not be empty)

This might override an existing entry. If key or node are nil, nothing happens. If the name is already in the names array, it will be overwritten
*/
    public mutating func setNames(with particle: ATParticle?, for name: String?) {
        guard particle != nil && particle != nil && !name!.isEmpty else { return }

        _names[name!] = particle
    }

/**
Remove an ATParticle to the nodes array based on a unique name.
 - parameters :
    - key:  unique String to identify the node (must not be empty)

*/
    public mutating func removeParticleFromNames(for key: String?) {
        guard key != nil && !key!.isEmpty else { return }
        _names.removeValue(forKey: key!)
    }

    public func getParticleFromNames(for key: String?) -> ATParticle? {
        guard key != nil && !key!.isEmpty else { return nil }

        return _names[key!]
    }

    public mutating func deleteAll() {
        _particles = [:]
        _springs = [:]
        _outboundAdjacency = [:]
        _inboundAdjacency = [:]
        _names = [:]

    }
}
