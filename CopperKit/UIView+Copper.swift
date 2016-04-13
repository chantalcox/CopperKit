//
//  Copper+UIImage
//  Copper
//
//  Created by Doug Williams on 11/2/15.
//  Copyright (c) 2015 Doug Williams. All rights reserved.
//

import UIKit

extension UIView {
    
    // add a blur overlay to an image
    public func blur(style: UIBlurEffectStyle, vibrancy: Bool = false, blurFrame: CGRect! = nil) {
        
        // add a blur
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        // set it in the same frame as the imageView, or the specified frame if present
        var frame = self.frame
        if let blurFrame = blurFrame {
            frame = blurFrame
        }
        blurView.frame = frame
        
        // Make the Blur happen!
        self.addSubview(blurView)
        
        // optionally add vibrancy
        if vibrancy {
            let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.frame = blurView.bounds
            self.addSubview(vibrancyEffectView)
        }
    }
    
    
    // credit http://stackoverflow.com/a/23157272
    public func addBorder(edges edges: UIRectEdge, color: UIColor = UIColor.whiteColor(), thickness: CGFloat = 1, bottomLeftInset: CGFloat = 0.0) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRectZero)
            border.backgroundColor = color
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.Top) || edges.contains(.All) {
            let top = border()
            addSubview(top)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.Left) || edges.contains(.All) {
            let left = border()
            addSubview(left)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.Right) || edges.contains(.All) {
            let right = border()
            addSubview(right)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.Bottom) || edges.contains(.All) {
            let bottom = border()
            addSubview(bottom)
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(\(bottomLeftInset))-[bottom]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        return borders
    }
    
    public func addGradient(topColor: UIColor, bottomColor: UIColor) {
        let gradientColors: [CGColor] = [topColor.CGColor, bottomColor.CGColor]
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.frame = self.bounds
        self.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    
    // recursive shake function -- designed to be used by simply calling self.shake(withConstraint: ), though you can reasonably configure shakeDistance and times
    public func shake(withConstraint constraint:NSLayoutConstraint, withShakeDistance distance: CGFloat = 15.0, animationDuration: Double = 0.04, times: Int = 3, state: Int = 0, callback: (()->())! = nil) {
        // exit on the base case
        if times == 0 {
            callback?()
            return
        }
        // get mutable variable values
        var times = times
        var state = state
        // otherwise, let's move
        UIView.animateWithDuration(animationDuration,
            animations: {
                if state == 0 || state == 3 {
                    constraint.constant = constraint.constant - distance
                } else {
                    constraint.constant = constraint.constant + distance
                }
                self.layoutIfNeeded()
            },
            completion: { finished in
                // update are vars
                if state >= 3 {
                    times = times - 1
                    state = 0
                } else {
                    state = state + 1
                }
                self.shake(withConstraint: constraint, withShakeDistance: distance, times: times, state: state, callback: callback)
            }
        )
    }
    
    public func noticeWiggle(withConstant constraint:NSLayoutConstraint, withWiggleDistance: CGFloat, animationDuration: Double, completion: (()->())! = nil) {
        let start = constraint.constant
        UIView.animateWithDuration(animationDuration * 0.85,
            delay: 0.0,
            usingSpringWithDamping: 0.3,
            initialSpringVelocity: 0.0,
            options: [.AllowUserInteraction],
            animations: {
                constraint.constant = start - withWiggleDistance
                self.layoutIfNeeded()
            },
            completion: { finished in
                UIView.animateWithDuration(animationDuration * 0.15,
                    animations: {
                        constraint.constant = start
                        self.layoutIfNeeded()
                    },
                    completion: { finished in
                        completion?()
                    }
                )
            }
        )
    }
    
}