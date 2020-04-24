//
//  CGRectExtension.swift
//  SystemRig
//
//  Created by arnaud on 12/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect {
        
    public func hasNearlySimilarSize(as rect: CGRect) -> Bool {
        return self.size.width == rect.size.width
            || self.size.height == rect.size.height ? true : false
    }
/** Create a CGRect based on the topLeft and bottomRight points.
                 
- returns: CGrect
*/

    public static func set(topLeft: CGPoint, bottomRight: CGPoint) -> CGRect? {
        guard topLeft.x <= bottomRight.x else { return nil }
        guard topLeft.y <= bottomRight.y else { return nil }

        return CGRect(x: topLeft.x,
                y: topLeft.y,
                width: bottomRight.x - topLeft.x,
                height: bottomRight.y - topLeft.y)
    }
/** increase the rect to include the given point.
                     
- returns: CGrect
*/

    public func include(_ point: CGPoint) -> CGRect? {
        let topLeft = self.origin.minimum(point: point)
        var bottomRight = self.origin + self.size.asCGPoint
        bottomRight = bottomRight.maximum(point: point)
        return CGRect.set(topLeft: topLeft, bottomRight: bottomRight)
    }
/** Scale the width and height of a CGRect by a factor of 0.5.
         
- returns: CGSize
             
Example :
A CGRect of width 100 and height 80 scaled will result in a CGSize of width 50 and height 40.
*/
    public var halved: CGSize {
        CGSize(width: self.width * 0.5,
               height: self.height * 0.5)
    }

/**
Ensure that the width and height of a CGRect have a minimal dimension.

- parameters:
     - dimension: the minimal height and width

Otherwise the size and/or width will be enlarged to dimension. The origin will be offset by the difference between dimension and original sizes.
**/
    public func ensureMinimumDimension(_ dimension: CGFloat) -> CGRect? {
        if dimension <= 0.0 { return nil }
        
        // is the width to small?
        let requiredOutsetX = self.width < dimension ? ( dimension - self.width ) / 2.0 : CGFloat.zero
        
        // is the height to small?
        let requiredOutsetY = self.height < dimension ? ( dimension - self.height ) / 2.0 : CGFloat.zero
        
        return self.insetBy(dx: -requiredOutsetX, dy: -requiredOutsetY)
    }
    
/**
Scale a CGRect with respect to another CGRect by a scale factor.

- parameters:
    - rect: the CGRect that is targeted
    - delta: the sizing step (between 0 and 1). If smaller than 0, it will be set to 0. If larger than 1, it will be set to 1.

The size of the CGRect will be enlarged/diminised to that it is closer to the tweenTo CGRect, in size and position. The enlargement factor is determined by the scale of the differenes in position and size..
*/
    public func tweenTo(rect: CGRect, with scale: CGFloat) -> CGRect {
        var adjustedScale = scale < 0 ? 0.0 : scale
        adjustedScale = scale > 1 ? 1.0 : scale
        var tweenRect = CGRect.zero
        
        let distanceTotal = rect.origin.subtract(self.origin)
        tweenRect.origin = self.origin + distanceTotal.multiply(by: adjustedScale)
        
        var steppedSize = CGSize.zero
        steppedSize.width = self.width + ( rect.width - self.width) * adjustedScale
        steppedSize.height = self.height + ( rect.height - self.height) * adjustedScale
        tweenRect.size = steppedSize;
        
        return tweenRect;
    }

/** Give the quadrant of a point in a CGRect
                 
- parameter point : the point to check

- returns: CGSize.Quadrant
                         
Example :
A CGRect of (10, 5, 100, 30) with a CGPoint (60, 50) will result in
*/
    public func quadrant(containing point: CGPoint) -> CGSize.Quadrant {
        // first subract to the origin of the point
        return self.size.quadrant(containing: point.subtract(self.origin))
    }

    public var averageDistance: CGFloat {
        self.size.averageDistance
    }

}
