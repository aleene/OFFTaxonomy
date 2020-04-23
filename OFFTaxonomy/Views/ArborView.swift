//
//  AtlasCanvasView.swift
//  Atlas
//
//  Created by arnaud on 17/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit
import CoreGraphics

class ArborView: UIView {

// MARK: - constants
            
    private struct Constant {
        /// Scales the model to the screen. Note is very sensitive
        static let ViewScaleFactor = CGFloat(0.02)
        struct Tree {
            static let LineWidth = CGFloat(1.0)
            struct BarnesHutTree {
                static let LineColor = UIColor.yellow.cgColor
            }
            struct TweensCurrent {
                static let LineColor = UIColor.blue.cgColor
            }
            struct TweensTarget {
                static let LineColor = UIColor.green.cgColor
            }
        }
        struct Spring {
            static let LineWidth = CGFloat(2.0)
            static let LineColor = UIColor.gray.cgColor
        }
        struct Particle {
            // The size of the square around the particle
            static let Inset = -CGFloat(5.0)
            static let LineWidth = CGFloat(2.0)
            static let LineColor = UIColor.red.cgColor
            static let FontSize = CGFloat(12.0)
            static let FontName = "Helvetica Bold"
        }
    }

// MARK: - public variables
        
    public var system: ATSystem?
    public var isDebugDrawing: Bool = false
    public var scale = Constant.ViewScaleFactor {
        didSet {
            self.layoutSubviews()
        }
    }
    public var offset = CGPoint.zero {
        didSet {
            self.layoutSubviews()
        }
    }
    public var languageCode = "en"

// MARK: - public functions
            
//    override func layoutSubviews() {
//        self.system?.viewBounds = self.bounds;
//    }

    override func draw(_ rect: CGRect) {
        guard let validSystem = system else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        // reset the layers (for arrows only?)
        self.layer.sublayers = []

        if self.isDebugDrawing {
                    
        // Drawing code for the barnes-hut trees

            // yellow line
            context.setStrokeColor(Constant.Tree.BarnesHutTree.LineColor)
            context.setLineWidth(Constant.Tree.LineWidth)
                    
            recursiveDrawBranches(branch: validSystem.physics.bhTree.root, in: context)
                        
            // green line
            context.setStrokeColor(Constant.Tree.TweensTarget.LineColor)
            context.setLineWidth(Constant.Tree.LineWidth)
            drawOutline(with: context, and: scale(validSystem.tweenBoundsTarget))
                    
            // blue line
            context.setStrokeColor(Constant.Tree.TweensCurrent.LineColor)
            context.setLineWidth(Constant.Tree.LineWidth)
            drawOutline(with: context, and: scale(validSystem.tweenBoundsCurrent))
        }
                    
        // Drawing code for springs
                
        // black line with alpha
        context.setStrokeColor(Constant.Spring.LineColor)
        context.setLineWidth(Constant.Spring.LineWidth)
        for spring in validSystem.physics.springs {
            drawSpring(spring, in: context)
        }

        // Drawing code for particle centers

        // red line
        context.setStrokeColor(Constant.Particle.LineColor)
        context.setLineWidth(Constant.Particle.LineWidth)
        for particle in validSystem.physics.particles {
            drawText(for: particle, in: context)
            //drawParticle(particle, in:context)
        }
                    
    }

// MARK: - private scaling functions

        
    private func sizeToScreen(_ size: CGSize) -> CGSize {
        let scaledSize = self.bounds.size * self.scale
        return size.multiply(size: scaledSize)
    }

    private func pointToScreen(_ p: CGPoint) -> CGPoint {
            
        let mid = self.bounds.size.halved.asCGPoint
        let scale = self.bounds.size * self.scale
        return scale.asCGPoint * p + mid + self.offset
    }

    private func scale(_ rect: CGRect) -> CGRect {
        return CGRect(origin: pointToScreen(rect.origin),
                      size: sizeToScreen(rect.size))
    }

// MARK: - private drawing functions
        
    private func drawLineWith(context: CGContext, from: CGPoint, to: CGPoint) {
        context.beginPath()
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }

    private func drawOutline(with context: CGContext, and rect: CGRect) {
        context.beginPath()
        context.addRect(rect)
        context.strokePath()
    }
        
    private func recursiveDrawBranches(branch: ATBarnesHutBranch?, in context: CGContext) {
        guard let validBranch = branch else { return }
            
        drawOutline(with: context, and: scale(validBranch.bounds))

        validBranch.allQuadrantBranches.forEach({ self.recursiveDrawBranches(branch: $0, in:context) })
    }

    private func drawSpring(_ spring: ATSpring, in context: CGContext) {
        guard let position1 = spring.point1?.position else { return }
        guard let position2 = spring.point2?.position else { return }
            
        //drawLineWith(context: context, from: pointToScreen(position1), to: pointToScreen(position2))
        let arrow = UIBezierPath.arrow(from: pointToScreen(position1),
                           to: pointToScreen(position2),
                           tailWidth: 1.0,
                           headWidth: 10.0,
            headLength: 10.0)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrow.cgPath
        self.layer.addSublayer(shapeLayer)
    }

    private func drawParticle(_ particle: ATParticle, in context: CGContext) {
        // Translate the particle position to screen coordinates
        guard let position = particle.position else { return }
            
        let pOrigin = pointToScreen(position)
        // Create an empty rect at particle center
        var strokeRect = CGRect(x: pOrigin.x, y: pOrigin.y, width: .zero, height: .zero)
        // Expand the rect around the center
        strokeRect = strokeRect.insetBy(dx: Constant.Particle.Inset,
                                        dy: Constant.Particle.Inset)
        // Draw the rect
        context.stroke(strokeRect)
    }
        
    private func drawText(for particle: ATParticle, in context: CGContext) {
        // Translate the particle position to screen coordinates
        guard let validPosition = particle.position else { return }
        var validName = "not set"
        if let validData = particle.userData[languageCode] as? [String],
            let validFirst = validData.first {
            validName = validFirst
        } else if let valid = particle.name {
            validName = valid
        }

        let particleOrigin = pointToScreen(validPosition)
        // Create an empty rect at particle center
        var fillRect = CGRect(origin: particleOrigin, size: .zero)
        // Expand the rect around the center
        fillRect = fillRect.insetBy(dx: 20 * Constant.Particle.Inset,
        dy: Constant.Particle.Inset * 2)
        
        // Fill in the rect with current fill color
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(fillRect)
        // Set the text fill color
        context.setFillColor(UIColor.black.cgColor)
        // Draw the text label
        
        //[particle.name drawInRect:fillRect
        //                 withFont:[self font]
        //            lineBreakMode:NSLineBreakByTruncatingTail
        //                alignment:NSTextAlignmentCenter];
        let string = validName as NSString
        let textColor = UIColor.black
        let textFont = UIFont(name: Constant.Particle.FontName, size: Constant.Particle.FontSize)!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center

        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        
        string.draw(in: fillRect, withAttributes: textFontAttributes)
    }

}
