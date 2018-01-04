//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation
import UIKit



extension UIApplication {
    
    /// Sends the user to the Settings app to the specific app settings panel
    public class func openSettingsPanel() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
}

extension UIView {
    
    /// Creates a new UIView with a square frame and origin coordinates.
    ///
    /// - Parameter square: the size of width and height
    @objc public convenience init(square:CGFloat) {
        self.init(frame: .square(square) )
    }
    
    /// Creates a new view with origin coordinates and specified width and height.
    ///
    /// - Parameters:
    ///   - width: The width of the frame
    ///   - height: The height of the frame
    @objc public convenience init(width:CGFloat, height:CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    /// Helper accessor for getting and setting the `center.y` position.
    ///
    ///     // move view's center by 10 on the y-axis
    ///     view.centerY += 10
    public var centerY:CGFloat {
        get {
            return center.y
        }
        set {
            center = CGPoint(x: center.x, y: newValue)
        }
    }
    
    
    /// Helper accessor for getting and setting the `center.x` position.
    ///
    ///     // move view's center by 50 on the x-axis
    ///     view.centerX += 50
    public var centerX:CGFloat {
        get {
            return center.x
        }
        set {
            center = CGPoint(x: newValue, y: center.y)
        }
    }
    
    
    public func bundleImage(_ named: String) -> UIImage? {

        let bundle = Bundle(for: self.classForCoder)
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
    
    /// Returns an zero frame instance ready for autolayout.
    /// - parameter autolayout: true or false whether this view will be used in autolayout. If true is passed, `translatesAutoresizingMaskIntoConstraints` will be set to false.
    @objc public convenience init(autolayout: Bool) {
        self.init(frame: .zero)
        if autolayout {
            translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    /// Returns an zero frame instance ready for autolayout with an accessibility identifier useful for layout debugging.
    /// - parameter name: the string name to use for accessibilityIdentifier.
    @objc public convenience init(name: String) {
        self.init(autolayout: true)
        // Sets identifier for the view, helpful in debugging constraints.
        accessibilityIdentifier = name
    }
    
    /// Uses a CAShapeLayer as mask to round the corners defined in `corners` argument.
    /// Ex. myView.roundCorners([.topLeft,.topRight], radius: 10)
    public func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(square: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    public func addShadow(dx:CGFloat, dy:CGFloat, radius:CGFloat, opacity:CGFloat = 1, color:UIColor = UIColor.black) {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: dx, height: dy)
        layer.shadowOpacity = Float(opacity)
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    public func rounded(by:CGFloat = 2.0) {
        if by > 0 {
            layer.cornerRadius = bounds.longest / by
        }
    }

}


extension UIView {
    
    /// Animate a bounce effect on the view.
    public func bounce(duration:TimeInterval = 0.6, scales:[CGFloat] = [0.60,1.1,0.9,1]) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.duration = duration
        bounceAnimation.values = scales
        let f = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        bounceAnimation.timingFunctions = scales.map({ (_) -> CAMediaTimingFunction in return f })
        bounceAnimation.isRemovedOnCompletion = false
        layer.add(bounceAnimation, forKey: "bounce")
    }
    
    @available(iOS 10.0, *)
    /// Animate the change in alpha of the view.
    public func fade(to:CGFloat, duration:TimeInterval = 0.25, completion:CompletionBlock? = nil) {
        
        let anim = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.alpha = to
        }
        if let c = completion {
            anim.addCompletion { _ in c() }
        }
        anim.startAnimation()
    }
    
    /// Animate the fade out the view.
    @available(iOS 10.0, *)
    public func fadeOut(completion:CompletionBlock? = nil) {
        fade(to: 0, completion: completion)
    }
    
    /// Animate the fade in the view.
    @available(iOS 10.0, *)
    public func fadeIn(completion:CompletionBlock? = nil) {
        fade(to: 1, completion: completion)
    }
}



extension UIViewController {
    /// Instantiates a new controller embedded inside a UINavigationController.
    public var navigatable:UINavigationController {
        return UINavigationController(rootViewController: self)
    }
    
    @objc public func animatedDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    public func embeddedInDismissableSystemNavigation(style:UIBarButtonSystemItem = .cancel) -> UINavigationController {
        
        let buttonItem = UIBarButtonItem(barButtonSystemItem: style, target: self, action: #selector(UIViewController.animatedDismiss))
        
        let navController = UINavigationController(rootViewController: self)
        if style == .cancel {
            navigationItem.leftBarButtonItem = buttonItem
        } else {
            navigationItem.rightBarButtonItem = buttonItem
        }
        return navController
    }
}



// MARK: UIColor
extension UIColor {
    
    /// Returns a black color with a modified alpha component. Useful when creating
    /// fades or overlays with opacity.
    ///
    /// - parameter alpha: The opacity value (0.0 to 1.0)
    public convenience init(blackWithAlpha alpha:CGFloat) {
        self.init(red: 0, green: 0, blue: 0, alpha: alpha)
    }
    
}


extension UIImage {
    
    /// Save an image to the user's photo album.
    /// - note: For more options use `UIImageWriteToSavedPhotosAlbum()`
    public func saveToPhotosAlbum() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
    
    /// A synchronous method that sets the image based on the contents at a url.
    /// When transport security is enabled, all urls should be https.
    public convenience init?(urlString:String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(contentsOfURL: url)
    }

    /// A synchronous method that sets the image based on the contents of a NSURL
    /// When transport security is enabled, all urls should be https.
    public convenience init?(contentsOfURL url:URL) {
        do {// catches issues where the data is invalid as an image.
            let data = try Data(contentsOf: url, options: [])
            self.init(data: data)
        } catch {
            return nil
        }
    }
    
    /// Returns the data for the specified image in PNG format
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the PNG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    public var png: Data? { return UIImagePNGRepresentation(self) }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    public func jpeg(quality: CGFloat = 0.80) -> Data? {
        guard 0...1 ~= quality else { return nil }
        return UIImageJPEGRepresentation(self, quality)
    }
    
}


extension UIFont {
    
    public class func loadCustomFontWithName(name : String, ext:String, inBundle bundle:Bundle = Bundle.main) {
        
         if let path = bundle.path(forResource: name, ofType: ext),
            let data = NSData(contentsOfFile: path),
            let providerRef = CGDataProvider(data: data)
        {
            let font = CGFont(providerRef)
            //print("Registering font: \(font)")
            CTFontManagerRegisterGraphicsFont(font!, nil)
        } else {
            NSLog("[Err] Failed to register Font: \(name)")
        }
        
    }

}

extension UIButton {
    public func setImageFromUrl(_ link:String, contentMode mode: UIViewContentMode) {
        contentMode = mode
        if let url = URL(string: link) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) -> Void in
                guard let data = data, error == nil else { return }
                if let scaledImage = UIImage(data: data) {
       
                    DispatchQueue.main.async {
                        self.setImage(scaledImage, for: .normal)
                    }
                    
                }
            }).resume()
        }
    }
}


extension UILabel {
    
    /// Helper accessor the pointSize of the label's current font.
    public var pointSize:CGFloat {
        get {
            return font?.pointSize ?? 0
        }
        set {
            if let font = font {
                self.font = UIFont(name: font.fontName, size: newValue)
            }
        }
    }
}

extension UITextView {
    
    /// Helper accessor the pointSize of the text view's current font.
    public var pointSize:CGFloat {
        get {
            return font?.pointSize ?? 0
        }
        set {
            if let font = font {
                self.font = UIFont(name: font.fontName, size: newValue)
            }
        }
    }
}

extension UITextField {
    
    /// Helper accessor the pointSize of the text field's current font.
    public var pointSize:CGFloat {
        get {
            return font?.pointSize ?? 0
        }
        set {
            if let font = font {
                self.font = UIFont(name: font.fontName, size: newValue)
            }
        }
    }
}

extension UITableView {
    
    /// Animate scrolling the table view to the top.
    public func scrollToTop() {
        setContentOffset(.zero, animated: true)
    }
}



open class ModernViewController : UIViewController, ModernControllerConformance {
    private var needsSetupConstraints = true
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.setNeedsUpdateConstraints()
    }
    
    open func setupConstraints() {}
    
    override open func updateViewConstraints() {
        
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
        // According to Apple's doc, it should be called as the final step in the
        // implementation.
        super.updateViewConstraints()
    }
    
    open func updateInterface() {}
}


open class ModernTableController : ModernViewController, UITableViewDataSource, UITableViewDelegate {
    
    public let tableView = UITableView(autolayout: true)
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        ModernTableCell.register(withTableView: tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override open func setupConstraints() {
        let views = ["tableView":tableView]
        var layoutConstraints = [NSLayoutConstraint]()
        layoutConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)
        layoutConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: views)
        view.addConstraints(layoutConstraints)
    }
    
    override open func updateInterface() {}
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ModernTableCell.dequeueReusableCell(inTableView: tableView)
    }
}


@available(*, deprecated, renamed: "ModernTableCell", message: "This class has been deprecated in favor of ModernTableCell.")
open class ReusableTableCell : ModernTableCell {}

@available(*, deprecated, renamed: "ModernCollectionCell", message: "This class has been deprecated in favor of ModernCollectionCell.")
open class ReusableCollectionCell : ModernCollectionCell {}

@available(*, deprecated, renamed: "ModernHeaderFooterView", message: "This class has been deprecated in favor of ModernHeaderFooterView.")
open class ReusableHeaderFooterView : ModernHeaderFooterView {}
