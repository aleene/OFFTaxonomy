//
//  AtlasCanvasView.swift
//  Atlas
//
//  Created by arnaud on 17/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import UIKit
import CoreGraphics

protocol ArborViewProtocol {
    // Convert viewPort coordinates into physics coordinates
    func physicsCoordinate(for screenPoint: CGPoint) -> CGPoint
    func physicsCoordinate(for screenDistance: CGFloat) -> CGFloat?
    func physicsCoordinate(for screenSize: CGSize) -> CGSize?
    func physicsCoordinate(for screenRect: CGRect) -> CGRect?
    
    // Convert physics coordinates into viewPort coordinates
    func screenCoordinate(for physicsPoint: CGPoint) -> CGPoint
    func screenCoordinate(for physicsDistance: CGFloat) -> CGFloat
    func screenCoordinate(for physicsSize: CGSize) -> CGSize
    func screenCoordinate(for physicsRect: CGRect) -> CGRect
}

final class ArborView: UIView {

// MARK: - constants
            
    private struct Constant {
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
            static let Inset = -CGFloat(10.0)
            static let LineWidth = CGFloat(2.0)
            static let LineColor = UIColor.red.cgColor
            static let FontSize = CGFloat(12.0)
            static let FontName = "Helvetica Bold"
        }
    }

// MARK: - public variables
        
    public var system: ATSystem?
    public var isDebugDrawing: Bool = false
    public var languageCode = "en"
    public var delegate: ArborViewProtocol?
    public var focusNode: ATNode?
    public var focusDistance = 2

// MARK: - public functions
            
//    override func layoutSubviews() {
//        self.system?.viewBounds = self.bounds;
//    }

    override func draw(_ rect: CGRect) {
        guard let validSystem = system else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let validDelegate = delegate else { return }
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
            drawOutline(with: context, and: validDelegate.screenCoordinate(for: validSystem.tweenBoundsTarget))
                    
            // blue line
            context.setStrokeColor(Constant.Tree.TweensCurrent.LineColor)
            context.setLineWidth(Constant.Tree.LineWidth)
            drawOutline(with: context, and: validDelegate.screenCoordinate(for: validSystem.tweenBoundsCurrent))
        }
                    
        // Drawing code for springs
                
        // black line with alpha
        context.setStrokeColor(Constant.Spring.LineColor)
        context.setLineWidth(Constant.Spring.LineWidth)
        for spring in validSystem.physics.springs {
            // should the focus be applied?
            if _applyFocusDrawing {
                if let shouldDrawSource = validSystem.isInFocus(spring.source as? ATParticle, focus: self.focusNode, within: focusDistance), shouldDrawSource,
                    let shouldDrawTarget = validSystem.isInFocus(spring.target as? ATParticle, focus: self.focusNode, within: focusDistance), shouldDrawTarget {
                    drawSpring(spring, in: context)
                }
            } else {
                drawSpring(spring, in: context)
            }
        }

        // Drawing code for particle centers

        // red line
        context.setStrokeColor(Constant.Particle.LineColor)
        context.setLineWidth(Constant.Particle.LineWidth)
        for particle in validSystem.physics.particles {
            // should the focus be applied?
            if _applyFocusDrawing {
                if let shouldDraw = validSystem.isInFocus(particle, focus: self.focusNode, within: focusDistance), shouldDraw {
                    drawText(for: particle, in: context)
                }
            } else {
                drawText(for: particle, in: context)
            }
            //drawParticle(particle, in:context)
        }
    }

// MARK: - private variables
    
    private var _applyFocusDrawing: Bool {
        self.focusNode != nil
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
        guard let validRect = self.delegate?.screenCoordinate(for:  validBranch.bounds) else { return }
        drawOutline(with: context, and: validRect)

        validBranch.allQuadrantBranches.forEach({ self.recursiveDrawBranches(branch: $0, in:context) })
    }

    private func drawSpring(_ spring: ATSpring, in context: CGContext) {
        guard let position1 = spring.point1?.position else { return }
        guard let position2 = spring.point2?.position else { return }
        guard let source = self.delegate?.screenCoordinate(for: position1) else { return }
        guard let target = self.delegate?.screenCoordinate(for: position2) else { return }
        //drawLineWith(context: context, from: pointToScreen(position1), to: pointToScreen(position2))
        let arrow = UIBezierPath.arrow(from: source, to: target,
                           tailWidth: 2.0,
                           headWidth: 10.0,
                           headLength: 10.0)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrow.cgPath
        self.layer.addSublayer(shapeLayer)
    }

    private func drawParticle(_ particle: ATParticle, in context: CGContext) {
        // Translate the particle position to screen coordinates
        guard let position = particle.position else { return }
            
        guard let pOrigin = self.delegate?.screenCoordinate(for: position) else { return }
        // Create an empty rect at particle center
        var strokeRect = CGRect(origin: pOrigin, size: .zero)
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

        guard let particleOrigin = self.delegate?.screenCoordinate(for: validPosition) else { return }
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
