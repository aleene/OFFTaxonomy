//
//  CoreGraphicsOperators.swift
//  SystemRig
//
//  Created by arnaud on 13/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//
import Foundation
import CoreGraphics

/**
 A large set of inline operators has been defined to work on CoreGraphics elements, CGPoint, CGSize and CGRect.
 
 These operators help the readibility of functions on two of these CoreGraphics elements. The implementation of these operators refer back to the Extension implementation of these elements. This separate implementation allows testing these operators. (Creating direct tests does not seem to work(?))
 */

// MARK: - CGPoint operators

func ~=(lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.nearlySimilar(to: rhs)
    }

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return lhs.add(rhs)
    }

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return lhs.subtract(rhs)
}

func -(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return lhs.subtract(rhs)
}

func -(lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return lhs.subtract(rhs)
}

 func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return lhs.multiply(by: rhs)
}

func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return lhs.multiply(by:rhs)
}

func /(lhs: CGPoint, rhs: CGSize) -> CGPoint? {
    return lhs.divide(by: rhs)
}

func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint? {
    return lhs.divide(by: rhs)
}

// MARK: - CGSize operators

func ~=(lhs: CGSize, rhs: CGSize) -> Bool {
    return lhs.hasNearlySimilarSize(as :rhs)
}

 func -(lhs: CGSize, rhs: CGFloat) -> CGSize {
    return lhs.subtract(by: rhs)
}

 func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
    return lhs.scale(by: rhs)
}

 func *(lhs: CGSize, rhs: CGPoint) -> CGSize {
    return lhs.mult(by: rhs)
}

func /(lhs: CGSize, rhs: CGFloat) -> CGSize? {
    return lhs.divide(by: rhs)
}


// MARK: - CGRect operators

 func ~=(lhs: CGRect, rhs: CGRect) -> Bool {
    return lhs.hasNearlySimilarSize(as: rhs)
}


