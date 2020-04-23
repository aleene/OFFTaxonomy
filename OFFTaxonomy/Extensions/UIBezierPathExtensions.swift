//
//  UIBezierPathExtensions.swift
//  OFFTaxonomy
//
//  Created by arnaud on 21/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//
//  Rob Mayoff 06/2016
// https://stackoverflow.com/questions/13528898/how-can-i-draw-an-arrow-using-core-graphics/37985645#37985645

import Foundation
import UIKit

extension UIBezierPath {

    /// let arrow = UIBezierPath.arrow(from: CGPoint(x: 50, y: 100), to: CGPoint(x: 200, y: 50),
    ///tailWidth: 10, headWidth: 25, headLength: 40)
    static func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
        let points: [CGPoint] = [
            p(0, tailWidth / 2),
            p(tailLength, tailWidth / 2),
            p(tailLength, headWidth / 2),
            p(length, 0),
            p(tailLength, -headWidth / 2),
            p(tailLength, -tailWidth / 2),
            p(0, -tailWidth / 2)
        ]

        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)

        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()

        return self.init(cgPath: path)
    }

}
