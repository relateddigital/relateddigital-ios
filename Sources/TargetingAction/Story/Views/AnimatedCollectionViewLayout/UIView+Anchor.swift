//
//  UIView+Anchor.swift
//  AnimatedCollectionViewLayout
//
//  Created by Jin Wang on 8/2/17.
//  Copyright © 2017 Uthoft. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func keepCenterAndApplyAnchorPoint(_ point: CGPoint) {

        guard layer.anchorPoint != point else { return }

        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var newPos = layer.position
        newPos.x -= oldPoint.x
        newPos.x += newPoint.x

        newPos.y -= oldPoint.y
        newPos.y += newPoint.y

        layer.position = newPos
        layer.anchorPoint = point
    }
}

extension UIButton {
    func setDashedBorder(width: CGFloat = 2, color: UIColor = .black) {
        
        let dashedBorderKey = "dashedBorder"
        
        if let subLayers = self.layer.sublayers {
            for element in subLayers {
                if element.name == dashedBorderKey {
                    element.removeFromSuperlayer()
                }
            }
        }
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)

        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [4, 4]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
        shapeLayer.name = dashedBorderKey

        self.layer.addSublayer(shapeLayer)
    }
}
