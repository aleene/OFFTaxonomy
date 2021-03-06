//
//  Taxonomy.swift
//  OFFTaxonomy
//
//  Created by arnaud on 25/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation

public class BHTaxonomy {
    
    var sections: [Section] = []
    
    public func createNodes() -> Set <ATParticle> {
        var nodes = Set <ATParticle>()
        // loop over all off entries
        for index in 0 ..< sections.count {
            let node = ATParticle(name: sections[index].key, userData: sections[index].leaves)
            //let node = Node(key: sections[index].key)
            //node.leaves = sections[index].leaves
            // Does the node with this name already exist?
            let existingNodes = nodes.filter({ $0.name! == node.name! })
            if existingNodes.isEmpty {
                nodes.insert(node)
            } else {
                print("Trying to insert a node whose nam already exists")
            }
        }
        return nodes
    }
    
    // This function creates for each off entry a vertex.
    // A vertex consists of the basic information in an off entry
    // i.e. the key, the language translations with synonyms
    // and ONLY the links to the parentVerteces
    // Thus a vertex is a copy of the off entries, but then as a set
    
    func createEdges() -> Set <ATSpring> {
        
        var edges = Set<ATSpring>()

        // first read all off entries to have a set of nodes
        // this step MUST be done before finding any relations
        let nodes = createNodes()
        
        // convert each node to a vertex with a parent link
        for node in nodes {
            // find the off entry for this node
            guard let key = node.name else {
                print("createEdges() - key missing")
                continue
            }
            let correspondingOFFentry = locateSection(testKey: key)
            //
            if let baseVertexParents = correspondingOFFentry?.parentKeys {
                // add the parents of this off entry to the vertex
                // for all parents defined
                for parentKey in baseVertexParents {
                    // locate the node equivalent of the parent off entry
                    if let parentNode = locateNode(searchKey: parentKey, inSet: nodes) {
                        let newSpring = ATSpring(source:parentNode, target:node, userData:[:])
                        let existingSprings = edges.filter({ ($0.source!.name! == node.name! && $0.target!.name! == parentNode.name! )
                            || ($0.source!.name! == parentNode.name! && $0.target!.name! == node.name! )
                        })
                        if existingSprings.isEmpty {
                            edges.insert(newSpring)
                        } else {
                            print("Issue")
                        }
                    }
                }
            }
        }
        return edges
    }

    
    func locateNode(searchKey: String, inSet: Set<ATParticle>) -> ATParticle? {
        for node in inSet {
            if node.name == searchKey {
                return node
            }
        }
        return nil
    }
    
    func locateSection(testKey: String) -> Section? {
        // loop over all branches
        // change to repeat while?
        for section in sections {
            if section.key == testKey {
                // key is at the toplevel
                return section
            }
        }
        return nil
    }

    func cleanAndPurge(languageArray: [String]) {
        // loop over all sections
        for section in sections {
            // loop over all language leaves
            for leaf in section.leaves {
                if !languageArray.contains(leaf.0) {
                    section.leaves.removeValue(forKey: leaf.0)
                }
            }
            
            // clean the section key
            var newKey = ""
            for character in section.key {
                let characterAsString = String(character)
                // replace space with dash
                if character == " " {
                    newKey += "-"
                } else {
                    // set to lower case
                    newKey += characterAsString.lowercased()
                }
            }
            section.key = newKey
        }

    }
}
