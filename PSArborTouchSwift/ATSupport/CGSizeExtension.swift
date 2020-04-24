//
//  CGSizeExtension.swift
//  SystemRig
//
//  Created by arnaud on 08/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension CGSize {

    public func hasNearlySimilarSize(as size: CGSize) -> Bool {
        return self.width == size.width || self.height == size.height ? true : false
    }
    
/** Transforms a CGSize into a CGPoint.
                  
- returns: CGPoint
*/
    public var asCGPoint: CGPoint {
        return CGPoint(x: self.width,
                        y: self.height)
    }

/** Scale the width and height of a CGSize by a factor.
     
- parameter factor : the scaling factor to use
     
- returns: CGFloat
     
Example :
A CGSize of width 100 and height 80 scaled by a factor 0.25, will result in a CGSize of width 25 and height 20.
 */
    public func scale(by factor: CGFloat) -> CGSize {
        return CGSize(width: self.width * factor,
                      height: self.height * factor)
    }
    
    public func mult(by point: CGPoint) -> CGSize {
        return CGSize(width: self.width * point.x,
                      height: self.height * point.y)
    }

    public func divide(by value: CGFloat) -> CGSize? {
        guard value != .zero else { return nil }
        return CGSize(width: self.width / value,
                      height: self.height / value)
    }

/** Scale the width and height of a CGSize by a factor of 0.5.
     
- returns: CGFloat
         
Example :
A CGSize of width 100 and height 80 scaled will result in a CGSize of width 50 and height 40.
*/
    public var halved: CGSize {
        self.scale(by: 0.5)
    }

/** Reduce the width and height of a CGSize by a value.
     
- parameter value : the value to reduce.

- returns: CGFloat
             
Example :
A CGSize of width 100 and height 80 scaled, and a value of 20, will result in a CGSize of width 80 and height 60.
*/
    public func reduce(by value: CGFloat) -> CGPoint {
        return CGPoint(x: self.width - value,
                      y: self.height - value)
    }

    public func subtract(by value: CGFloat) -> CGSize {
        return CGSize(width: self.width - value,
                      height: self.height - value)
    }

    public var averageDistance: CGFloat {
        sqrt(self.width * self.height)
    }
/** Multiply two CGSize, i.e. thwe widths and the heights separately.
         
- parameter size : the other CGSize.

    - returns: CGSize                 
*/
    public func multiply(size: CGSize) -> CGSize {
        return CGSize(width: self.width * size.width,
                      height: self.height * size.height)
    }

/** Apply a padding to a CGSize.
         
- parameter padding : the values (right, left, top, bottom) to pad. with

- returns: CGFloat
                 
Example :
A CGSize of width 100 and height 80 padded with values of (10, 8, 5 and 6), will result in a CGSize of width 82 and height 69.
*/
    
    public func pad(with padding: UIEdgeInsets) -> CGSize {
        return CGSize(width: self.width - ( padding.left + padding.right ),
                      height: self.height - ( padding.top + padding.bottom ))
    }
    
    //- (CGSize) toViewSize:(CGSize)physicsSize;
    public func toView(viewSize: CGSize, screenSize: CGSize, viewMode: ATViewConversion) -> CGSize {
        
        let scaleWidth = self.width / screenSize.width
        let scaleHeight = self.height / screenSize.height
        
        var newSize = CGSize()
        switch viewMode {
        case .scale:
            let uniformScale = min(viewSize.width, viewSize.height)
            newSize.width = scaleWidth * uniformScale
            newSize.height = scaleHeight * uniformScale
            
        case .stretch:
            newSize.width = scaleWidth * viewSize.width
            newSize.height = scaleHeight * viewSize.height
        }
        
        return newSize

    }
    
    public enum Quadrant {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        var isBottom: Bool {
            switch self {
            case .bottomLeft, .bottomRight:
                return true
            case .topLeft, .topRight:
                return false
            }
        }
        
        var isTop: Bool {
            !isBottom
        }
        
        var isRight: Bool {
            switch self {
            case .topRight, .bottomRight:
                return true
            case .topLeft, .bottomLeft:
                return false
            }
        }
        
        var isLeft: Bool {
            !isRight
        }

    }

/** Provides the quadrant of a point in a CGRect
             
- parameter point : the point to check

- returns: BHLocation
                     
Example :
A CGSize of width 100 and height 80 and a CGPoint(60, 60), will return southEast.
*/
    public func quadrant(containing point: CGPoint) -> CGSize.Quadrant {
        if point.y < self.halved.height {
            return point.x < self.halved.width ? .topLeft : .topRight
        } else {
            return point.x < self.halved.width ? .bottomLeft : .bottomRight
        }

    }
}

extension UIEdgeInsets {
    
    var topRight: CGPoint {
        CGPoint(x: self.right, y: self.top)
    }
}
