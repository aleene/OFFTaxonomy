//
//  ATBarnesHutNode.swift
//  SystemRig
//
//  Created by arnaud on 11/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//
infix operator ~=

import Foundation

public enum ATBarnesHutNode {
    case particle(ATParticle)
    case tree(ATBarnesHutBranch)
    case undefined
    

}

extension ATBarnesHutNode {
    
    static func ~=(lhs: ATBarnesHutNode, rhs: ATBarnesHutNode) -> Bool {
        switch (lhs, rhs) {
        case (.particle(_), .particle(_)):
            return true

        case (.tree(_), .tree(_)):
            return true

        case (.undefined, .undefined):
            return true

        default:
            return false
        }
    }
}

// MARK: - Equatable protocol

extension ATBarnesHutNode: Equatable {
    
    public static func ==(lhs: ATBarnesHutNode, rhs: ATBarnesHutNode) -> Bool {
        switch (lhs, rhs) {
        case (let .particle(codeA1), let .particle(codeA2)):
            return codeA1 == codeA2

        case (let .tree(code1), let .tree(code2)):
            return code1 == code2

        case (.undefined, .undefined):
            return true

        default:
            return false
        }
    }
}
