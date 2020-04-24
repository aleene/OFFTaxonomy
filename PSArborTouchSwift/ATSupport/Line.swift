//
//  Line.swift
//  SystemRig
//
//  Created by arnaud on 07/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation
import CoreGraphics

public struct Line {
    
    public var start = CGPoint.zero
    
    public var end = CGPoint.zero
    
    public init() {
        
    }
    
    public init(start: CGPoint, end: CGPoint) {
        self.init()
        self.start = start
        self.end = end
    }
    
    public func distance(to point: CGPoint) -> CGFloat {
        let A = point.x - start.x
        let B = point.y - start.y
        let C = end.x - start.x
        let D = end.y - start.y

        let dot = A * C + B * D
        let len_sq = C * C + D * D
        let param = dot / len_sq

        var xx, yy: CGFloat

        if param < 0 || (start.x == end.x && start.y == end.y) {
            xx = start.x
            yy = start.y
        } else if param > 1 {
            xx = end.x
            yy = end.y
        } else {
            xx = start.x + param * C
            yy = start.y + param * D
        }

        let dx = point.x - xx
        let dy = point.y - yy

    return sqrt(dx * dx + dy * dy)
    }

}


