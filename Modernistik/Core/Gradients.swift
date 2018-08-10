//
//  Gradients.swift
//  PocketSalsa
//
//  Created by Anthony Persaud on 7/17/14.
//  Copyright © 2014 Modernistik LLC. All rights reserved.
//

import QuartzCore

open
class GradientLayerView: ModernView {
    
    override open class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    /// Returns a simple linear CAGradientLayer that goes from the start color to the end color.
    /// - parameter start: The starting color of the gradient, defaults to clear.
    /// - parameter end: the ending color of the gradient, defaults to black.
    public static func layer(from startColor:UIColor, to endColor:UIColor) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        return gradient
    }
    
    // Helper to return the main layer as CAGradientLayer
    public var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    public var startColor: UIColor = .clear {
        didSet{
            updateInterface()
        }
    }
    
    public var endColor: UIColor = .black {
        didSet{
            updateInterface()
        }
    }
    
    public var isHorizontal: Bool = false {
        didSet{
            updateInterface()
        }
    }
    
    public var isReversed: Bool = false {
        didSet{
            updateInterface()
        }
    }
    
    public var roundness: CGFloat = 0.0 {
        didSet{
            updateInterface()
        }
    }
    
    open override func setupView() {
        backgroundColor = .clear
        updateInterface()
    }
    
    open override func updateInterface() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        
        let colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.colors = colors
        gradientLayer.cornerRadius = roundness
        let startPoint = CGPoint.zero
        let endPoint = isHorizontal ? CGPoint(x: 1, y: 0) : CGPoint(x: 0, y: 1)
        
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        if isReversed {
            gradientLayer.startPoint = endPoint
            gradientLayer.endPoint = startPoint
        }
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        backgroundColor = UIColor.clear
        updateInterface()
    }
    
    
}

open class SmoothGradientView : ModernView {
    
    public var startColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var endColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var startLocation:CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var endLocation:CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Sets the default drawing options. Defaults to `drawsBeforeStartLocation` and `drawsBeforeStartLocation`
    public var drawOptions:CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsBeforeStartLocation] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var startPoint = CGPoint.zero {
        didSet {
            setNeedsDisplay()
        }
    }
    public var endPoint = CGPoint(x: 0, y: 1) {
        didSet {
            setNeedsDisplay()
        }
    }
    public var isHorizontal = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override open func updateInterface() {
        setNeedsDisplay()
    }
    
    override open func draw(_ rect: CGRect) {
        //// General Declarations
        backgroundColor = .clear
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        //// Gradient Declarations
        let gradient = CGGradient(colorsSpace: nil,
                                  colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                                  locations: [startLocation, endLocation])!
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.width * startPoint.x, y: rect.height * startPoint.y),
                                   end: CGPoint(x: rect.width * endPoint.x, y: rect.height * endPoint.y),
                                   options: drawOptions
        )
        
        context.restoreGState()
    }
    
}
