//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation
import UIKit


#if os(iOS)
@available(tvOS,unavailable)
extension UIInterfaceOrientationMask {
    /// Returns an orientation mask for [.portrait, .portraitUpsideDown]
    @available(tvOS,unavailable)
    public static var vertical : UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
}
#endif

extension UIDevice {
    
    /// Returns true if the current interface idiom is an iPad
    public static var isPad:Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    /// Returns true if the current interface idiom is an iPhone or iPod Touch
    public static var isPhone:Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Returns true if the current interface idiom is an AppleTV
    public static var isTV:Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }
    
    /// Returns true if the current device is in vertical mode.
    @available(tvOS, unavailable)
    public static var isPortrait: Bool {
        return UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
    }
    
    /// Returns true if the current device is in landscape (horizontal) mode
    @available(tvOS, unavailable)
    public static var isLandscape: Bool {
        return UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
    }
    
    /// Returns true if the device is plugged into power
    /// and the battery is less than 100% charged.
    @available(tvOS, unavailable)
    public static var isCharging:Bool {
        let current = UIDevice.current
        current.isBatteryMonitoringEnabled = true
        return current.batteryState == .charging
    }
    /// Returns true if the device is not plugged
    /// into power; the battery is discharging.
    @available(tvOS, unavailable)
    public static var isUnplugged:Bool {
        let current = UIDevice.current
        current.isBatteryMonitoringEnabled = true
        return current.batteryState == .unplugged
    }
}

extension UIApplication {
    
    /// Sends the user to the Settings app to the specific app settings panel
    @available(tvOSApplicationExtension, unavailable)
    @available(iOSApplicationExtension, unavailable)
    public class func openSettingsPanel() {
        if let url = UIApplication.openSettingsURLString.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    
    /// Center this view within the provided rectangular area.
    public func center(in rect: CGRect) {
        center = CGPoint(x: rect.width / 2, y: rect.height / 2)
    }
    
    /// Return an image from the bundle for the current class.
    public func bundleImage(_ named: String) -> UIImage? {
        let bundle = Bundle(for: self.classForCoder)
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
    
    /// Returns an zero frame instance ready for autolayout.
    /// # Example
    /// ```
    /// // How to instantiate while subscribing to autolayout
    /// let view = UIView(autolayout: true)
    /// ```
    /// - parameter autolayout: true or false whether this view will be used in autolayout. If true is passed (default), `translatesAutoresizingMaskIntoConstraints` will be set to false.
    @objc public convenience init(autolayout: Bool) {
        self.init(frame: .zero)
        if autolayout { // if true, set it, otherwise leave default value.
            self.autolayout = true
        }
    }
    /// Alias to `translatesAutoresizingMaskIntoConstraints` that applies the inverse value. This
    /// just makes the settings more readable.
    @objc public var autolayout: Bool {
        get {
            return !translatesAutoresizingMaskIntoConstraints
        }
        set {
            translatesAutoresizingMaskIntoConstraints = !newValue
        }
    }
    
    /// Returns an zero frame instance ready for autolayout with an accessibility identifier useful for layout debugging.
    /// - parameter name: the string name to use for accessibilityIdentifier.
    @objc public convenience init(name: String) {
        self.init(autolayout: true)
        // Sets identifier for the view, helpful in debugging constraints.
        accessibilityIdentifier = name
    }
    
    /// Uses a CAShapeLayer as mask to round the corners defined in `corners` argument. (Mutating)
    /// # Example
    /// ```
    /// // round only the top left and right corners by 10.
    /// view.round(corners: [.topLeft,.topRight], radius: 10)
    /// ```
    public func round(corners: UIRectCorner, radius: CGFloat) {
        
        if #available(iOS 11.0, tvOS 11.0, *) {
            var maskedCorners:CACornerMask = []
            if corners.contains(.topLeft) { maskedCorners.insert(.layerMinXMinYCorner) }
            if corners.contains(.topRight) { maskedCorners.insert(.layerMaxXMinYCorner) }
            if corners.contains(.bottomLeft) { maskedCorners.insert(.layerMinXMaxYCorner) }
            if corners.contains(.bottomRight) { maskedCorners.insert(.layerMaxXMaxYCorner) }
            layer.cornerRadius = radius
            layer.maskedCorners = maskedCorners
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(square: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
            layer.masksToBounds = true
    }
    
    /// Adds a shadow to the view's layer given the parameters. Note, that this will set `maskToBounds` to false.
    /// - parameter dx: the horizontal offset amount of shadow. Applied to `shadowOffset`.
    /// - parameter dy: the vertical offset amount of shadow. Applied to `shadowOffset`.
    /// - parameter radius: the shadow radius. Alias to `shadowRadius`
    /// - parameter opacity: the shadow opacity. Alias to `shadowOpacity` and defaults to 0.5.
    /// - parameter color: the shadow color. Alias to `shadowColor` and defaults to black.
    public func addShadow(dx:CGFloat, dy:CGFloat, radius:CGFloat, opacity:CGFloat = 0.5, color:UIColor = UIColor.black) {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: dx, height: dy)
        layer.shadowOpacity = Float(opacity)
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// Makes the view rounded by setting the corner radius of the view to a dividing factor of the longest bounds dimension.
    /// # Example
    /// ```
    ///  view.rounded()
    ///  // which is shorthand for:
    ///  view.layer.cornerRadius = bounds.shortest / 2
    ///  view.layer.maskToBounds = true
    /// ```
    /// - parameter by : The dividing factor. Default is 2, which creates a circle.
    public func rounded(by factor:CGFloat = 2.0) {
        if factor > 0 {
            cornerRadius = bounds.shortest / factor
        }
    }
    
    /// Sets the layer's corner radius and enabled masking to its bounds.
    /// This is short hand for:
    /// ```
    /// view.cornerRadius = 10
    /// // shorthand for:
    /// view.layer.cornerRadius = 10
    /// view.layer.maskToBounds = true
    /// ```
    public var cornerRadius:CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    /// Returns a set of constraints where the current view is pinned to all sides to the supplied view.
    /// If the supplied view is the current view's parent, this would be similarly represented in the visual format of `H:|[view]|` and `V:|[view]|`.
    ///
    /// If both views are siblings, then the two views would overlap.
    ///
    /// - note: The returned constraints are not activated automatically.
    /// - parameter view: the view to use for the anchoring the constraints
    public func constraintsPinned(toView view:UIView) -> [NSLayoutConstraint] {
        return [topAnchor.constraint(equalTo: view.topAnchor),
        bottomAnchor.constraint(equalTo: view.bottomAnchor),
        leadingAnchor.constraint(equalTo: view.leadingAnchor),
        trailingAnchor.constraint(equalTo: view.trailingAnchor)]
    }
    /// An enum to use as parameters in sizing constraints.
    public enum SizeDimension {
        case width, height
    }
    
    /// Returns a constraint where view's aspect ratio is maintained dependent on a specific
    /// dimension. The method will make one layout dimension dependent to a multiple
    /// of the input layout dimension.
    ///
    /// This is useful alias method for making views maintain a specific aspect ratio, such as staying square.
    ///
    /// # Example 1: Staying Square
    /// Make the widthAnchor dependent on the heightAnchor to keep the view square.
    ///
    ///     v.constrainAspect(by: .height)
    ///     // equivalent to:
    ///     v.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1)
    ///
    /// # Example 2: Matching an Aspect Ratio
    /// Make a view maintain a 1920x1080 (HD) aspect ratio depending on the varying `width`.
    ///
    ///     // height = width * 1080/1920
    ///     v.constrainAspect(by: .width, ratio: 1080/1920)
    ///
    ///     // equivalent to:
    ///     v.widthAnchor.constraint(equalTo: v.heightAnchor, multiplier: 1080/1920)
    ///
    /// - note: The returned constraints are not activated automatically.
    /// - parameter dimension: the dependent dimension, either `.width` or `.height`.
    /// - parameter ratio: The multiplier constant for the constraint. Default is 1 for a square dimension.
    public func constrainAspect(by dimension: SizeDimension, ratio:CGFloat = 1) -> NSLayoutConstraint {
        return dimension == .height ?
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio) :
            heightAnchor.constraint(equalTo: widthAnchor, multiplier: ratio)
    }

}


extension UIView {
    
    /// Animate a bounce effect on the view.
    public func bounce(duration:TimeInterval = 0.6, scales:[CGFloat] = [0.60,1.1,0.9,1], completion:CompletionBlock? = nil) {
        CATransaction.begin()
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.duration = duration
        bounceAnimation.values = scales
        let f = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        bounceAnimation.timingFunctions = scales.map({ (_) -> CAMediaTimingFunction in return f })
        bounceAnimation.isRemovedOnCompletion = false
        layer.add(bounceAnimation, forKey: "bounce")
        CATransaction.setCompletionBlock {
            completion?()
        }
        CATransaction.commit()
    }
    
    @available(iOS 10.0, tvOS 10, *)
    /// Animate the change in alpha of the view.
    public func fade(to:CGFloat, duration:TimeInterval = 0.25, completion:CompletionBlock? = nil) {
        if alpha == to { completion?(); return }
        let anim = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.alpha = to
        }
        if let c = completion {
            anim.addCompletion { _ in c() }
        }
        anim.startAnimation()
    }
    
    /// Animate the fade out the view.
    @available(iOS 10.0, tvOS 10, *)
    public func fadeOut(completion:CompletionBlock? = nil) {
        fade(to: 0, completion: completion)
    }
    
    /// Animate the fade in the view.
    @available(iOS 10.0, tvOS 10, *)
    public func fadeIn(completion:CompletionBlock? = nil) {
        fade(to: 1, completion: completion)
    }
    
    public func shake(dx:CGFloat = 10, completion:CompletionBlock? = nil) {
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - dx, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + dx, y: center.y))
        layer.add(animation, forKey: "shake")
        CATransaction.setCompletionBlock {
            completion?()
        }
        CATransaction.commit()
    }
}



extension UIViewController {
    
    /// Shorthand for observing a notification in a UIViewController in the default NotificationCenter.
    ///
    /// Equivalent to `NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)`
    public func addNotificationObserver(name:Notification.Name, selector:Selector, object:Any? = nil) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: object)
    }
    
    /// Instantiates a new controller embedded inside a UINavigationController.
    public var navigatable:UINavigationController {
        return UINavigationController(rootViewController: self)
    }
    /// Shorthand for dismissing the controller. Useful when needed to be set as a selector to an action.
    @objc public func animatedDismiss() {
        dismiss(animated: true, completion: nil)
    }
    /// Returns a UINavigationController with this controller set at its root with a cancel button that will call `animatedDismiss`. You may change the set bar button item style. Useful for quick presentations.
    public func embeddedInDismissableSystemNavigation(style:UIBarButtonItem.SystemItem = .cancel) -> UINavigationController {
        
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
    
    /// Alias to `withAlphaComponent(value)`.
    /// Creates and returns a color object that has the same color space
    /// and component values as the receiver, but has the specified alpha component.
    public func opacity(_ alpha:CGFloat) -> UIColor {
        return self.withAlphaComponent(alpha)
    }
    
    /// Creates a new UIColor with using natural RGB numbers which will be divided by 255.
    /// If the value provided for any field is less than `1.0`,
    /// it will assume you've already done the division by `255`.
    /// Example:
    ///
    ///     UIColor(r: 108, green: 114, blue: 124)
    ///     // equivalent to:
    ///     UIColor(red: 108/255.0, green: 114/255.0, blue: 124/255.0)
    ///
    /// - parameter r: The red color integer value between 0 and 255.
    /// - parameter g: The green color integer value between 0 and 255.
    /// - parameter b: The blue color integer value between 0 and 255.
    /// - parameter a: The alpha value (opacity) between 0 and 1.0. Defaults to 1.0
    public convenience init(r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat = 1) {
        let amountRed = r > 1.0 ? r/255.0 : r
        let amountGreen = g > 1.0 ? g/255.0 : g
        let amountBlue = b > 1.0 ? b/255.0 : b
        self.init(red: amountRed, green: amountGreen, blue: amountBlue, alpha: a)
    }
    
    /// Creates a new UIColor with the same value for all RGB fields.
    /// Example:
    ///
    ///     UIColor(all: 142)
    ///     UIColor(all: 0.556)
    ///     // equivalent to:
    ///     UIColor(red: 142/255.0, green: 142/255.0, blue: 142/255.0)
    ///     UIColor(red: 0.556, green: 0.556, blue: 0.556)
    ///
    /// - parameter all: The color value (fractional or natural) to apply to color values.
    public convenience init(all:CGFloat, alpha:CGFloat = 1) {
        let amount = all > 1.0 ? all/255.0 : all
        self.init(red: amount, green: amount, blue: amount, alpha: alpha)
    }
}


extension UIImage {
    
    #if os(iOS)
    /// Save an image to the user's photo album.
    /// - note: For more options use `UIImageWriteToSavedPhotosAlbum()`
    public func saveToPhotosAlbum() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
    #endif
    
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
    public var png: Data? { return self.pngData() }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    public func jpeg(quality: CGFloat = 0.80) -> Data? {
        guard 0...1 ~= quality else { return nil }
        return self.jpegData(compressionQuality: quality)
    }
    
}


extension UIFont {
    
    public class func loadCustomFontWithName(name : String, ext:String, inBundle bundle:Bundle = Bundle.main) {
        
         if let path = bundle.path(forResource: name, ofType: ext),
            let data = NSData(contentsOfFile: path),
            let providerRef = CGDataProvider(data: data),
            let font = CGFont(providerRef)
        {
            //print("Registering font: \(font)")
            CTFontManagerRegisterGraphicsFont(font, nil)
        } else {
            NSLog("[Err] Failed to register Font: \(name)")
        }
        
    }

}

extension UIButton {
    public func setImageFromUrl(_ link:String, contentMode mode: UIView.ContentMode) {
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

extension UICollectionView {
    // Creates an autolayout enabled UICollectionView utilizing a UICollectionViewFlowLayout.
    /// - parameter autolayout: true or false whether this view will be used in autolayout. If true is passed (default), `translatesAutoresizingMaskIntoConstraints` will be set to false.
    public convenience init(autolayout:Bool = true) {
        self.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        if autolayout { // if true,
            translatesAutoresizingMaskIntoConstraints = false
        }
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
        ModernTableCell.register(with: tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override open func setupConstraints() {
        var layoutConstraints = [
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        if #available(iOS 11.0, tvOS 11.0, *) {
            layoutConstraints += [
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ]
        } else {
            layoutConstraints += [
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        }
        view.addConstraints(layoutConstraints)
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return ModernTableCell.dequeueReusableCell(in: tableView)
    }
}

open class ModernCollectionController : ModernViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        ModernCollectionCell.register(with: collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        // Do any additional setup after loading the view.
    }
    
    open override func setupConstraints() {
        var layoutConstraints = [
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        if #available(iOS 11.0, tvOS 11.0, *) {
            layoutConstraints += [
                collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ]
        } else {
            layoutConstraints += [
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        }
        view.addConstraints(layoutConstraints)
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return ModernCollectionCell.dequeueReusableCell(in: collectionView, for: indexPath)
    }
    
    
}
