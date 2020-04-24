//
//  CGPointExtension.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics
import UIKit

/**
The CGPoint extensions define operations that can be done on the CGPoints.

 These operations have been taken out of the main code to improve the readibility of the code and to allow the creation of tests for these (simple) operations.
*/
extension CGPoint {
    
/** Are the x- or y-values of two CGPoints the same?
                     
- parameter point : the point to compare with
         
- returns: Bool
                             
- Example :
A CGPoint (10, 20) compared with CGPoint (5,20) will return true
*/
    public func nearlySimilar(to point: CGPoint) -> Bool {
        return self.x == point.x || self.y == point.y ? true : false
    }
    
/**
Add two CGPoint's
                         
- parameter point : the point to add
             
- returns: CGPoint
                                 
- Example :
    A CGPoint (10, 20) addd with CGPoint (5,20) will return a CGPoint(15,40)
*/
    public func add(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }

/**
Subtract two CGPoint's
                             
- parameter point : the point to subtract
                 
- returns: CGPoint
                                     
- Example :
A CGPoint (10, 20) subtracted with CGPoint (5,20) will return a CGPoint(5,0)
*/

    public func subtract(_ value: CGFloat) -> CGPoint {
        return CGPoint(x: self.x - value, y: self.y - value)
    }

    public func subtract(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x - point.x, y: self.y - point.y)
    }

    public func subtract(_ size: CGSize) -> CGPoint {
        return CGPoint(x: self.x - size.width, y: self.y - size.height)
    }

    public func multiply(by point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x * point.x, y: self.y * point.y)
    }

/** Multiply operator for multiplying a CGPoint with a CGFloat
                 
- parameter lhs : the point
- parameter rhs: the float to scale with
     
- returns: CGPoint
                         
Example :
A CGPoint (10, 20) can be multiplied by a CGFloat of 0.5, will result in a CGPoint (5,10).
*/
    public func multiply(by value: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * value, y: self.y * value)
    }

    public func divide(by size: CGSize) -> CGPoint? {
        guard size.width != .zero && size.height != 0 else { return nil }
        return CGPoint(x: self.x / size.width,
                      y: self.y / size.height)
    }

    public func divide(by n: CGFloat) -> CGPoint? {
        //assert(n != 0.0, "CGPointExtension.divide(byN:) - n is 0.0")
        guard n != 0.0 else { return nil }
    
        return CGPoint(x: self.x / n, y: self.y / n)
    }
    
    public func divideSize(_ size: CGSize) -> CGPoint? {
        //assert(n != 0.0, "CGPointExtension.divide(byN:) - n is 0.0")
        guard size.width != 0.0 else { return nil }
        guard size.height != 0.0 else { return nil }

        return CGPoint(x: self.x / size.width, y: self.y / size.height)
    }

    public func distance(to point: CGPoint) -> CGFloat {
        let xDelta = point.x - self.x
        let yDelta = point.y - self.y
        return sqrt(xDelta * xDelta + yDelta * yDelta)
    }

    public var magnitude: CGFloat {
        sqrt(self.x * self.x + self.y * self.y)
    }

    public var normal: CGPoint {
        CGPoint(x: self.x, y: -self.y)
    }

    public var normalize: CGPoint? {
        self.divide(by: self.magnitude)
    }
    
    /// Creates a point around (0.0) within a circle with radius radius. Radius must be larger than zero
    public static func random(radius: CGFloat) -> CGPoint? {
        //assert(radius > 0.0, "CGPointExtension.random(radius:) - radius is smaller than 0")
        guard radius > 0.0 else { return nil }
        return CGPoint(x: radius * 2 * (CGFloat(Double.random(in:0.0...1.0)) - 0.5),
                       y: radius * 2 * (CGFloat(Double.random(in:0.0...1.0)) - 0.5))
    }

    /// Creates a point around self within a circle with radius radius. Radius must be larger than zero.
    public func nearPoint(radius: CGFloat) -> CGPoint? {
        //assert(radius > 0.0, "CGPointExtension.nearPoint(radius:) - radius is smaller than 0")
        guard radius >= 0.0 else { return nil }
        guard let validPoint = CGPoint.random(radius: radius) else { return nil }
        return self.add(validPoint)
    }

    public func direction(radius: CGFloat) -> CGPoint? {
        guard let validRandomPoint = CGPoint.random(radius: 1.0) else { return nil }
        return self.magnitude > .zero ? self.normalize : validRandomPoint.normalize
    }
    
    public func scaleInRect(_ rect: CGRect) -> CGPoint? {
        self.subtract(rect.origin).divideSize(rect.size)
    }
    
    public func maximum(point: CGPoint) -> CGPoint {
        var newPoint = CGPoint.zero
        newPoint.x = self.x > point.x ? self.x : point.x
        newPoint.y = self.y > point.y ? self.y : point.y
        return newPoint
    }
    
    public func minimum(point: CGPoint) -> CGPoint {
        var newPoint = CGPoint.zero
        newPoint.x = self.x < point.x ? self.x : point.x
        newPoint.y = self.y < point.y ? self.y : point.y
        return newPoint
    }

}
