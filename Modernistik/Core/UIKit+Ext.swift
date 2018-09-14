//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation
import UIKit



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
    public class func openSettingsPanel() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
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
    /// - parameter autolayout: true or false whether this view will be used in autolayout. If true is passed (default), `translatesAutoresizingMaskIntoConstraints` will be set to false.
    @objc public convenience init(autolayout: Bool) {
        self.init(frame: .zero)
        if autolayout { // if true, set to false, otherwise leave default value.
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
    
    /// Adds a shadow to the view's layer given the parameters.
    /// - parameter dx: the horizontal offset amount of shadow. Applied to `shadowOffset`.
    /// - parameter dy: the vertical offset amount of shadow. Applied to `shadowOffset`.
    /// - parameter radius: the shadow radius. Alias to `shadowRadius`
    /// - parameter opacity: the shadow opacity. Alias to `shadowOpacity` and defaults to 1.
    /// - parameter color: the shadow color. Alias to `shadowColor` and defaults to black.
    public func addShadow(dx:CGFloat, dy:CGFloat, radius:CGFloat, opacity:CGFloat = 1, color:UIColor = UIColor.black) {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: dx, height: dy)
        layer.shadowOpacity = Float(opacity)
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// Makes the vide rounded. Rounds the corners of the view dividing the current longest bounds dimension by an amount.
    /// This is short hand for:
    ///
    ///     layer.cornerRadius = bounds.longest / 2
    ///     layer.maskToBounds = true
    ///
    /// - parameter by : The dividing factor. T default is 2 which creates a circle.
    public func rounded(by factor:CGFloat = 2.0) {
        if factor > 0 {
            cornerRadius(bounds.longest / factor)
            layer.cornerRadius = bounds.longest / factor
            layer.masksToBounds = true
        }
    }
    
    /// Sets the layer's corner radius and enabled masking to its bounds.
    /// This is short hand for:
    ///
    ///     layer.cornerRadius = amount
    ///     layer.maskToBounds = true
    ///
    public func cornerRadius(_ amount:CGFloat) {
        layer.cornerRadius = amount
        layer.masksToBounds = true
    }
    
    /// Returns a set of constraints where the current view is pinned to all sides to the supplied view.
    /// If the supplied view is the current view's parent, this would be similarly represented in the visual format of `H:|[view]|` and `V:|[view]|`.
    ///
    /// If both views are siblings, then the two views would overlap.
    ///
    /// - Note: The returned constraints are not activated automatically.
    /// - Parameter view: the view to use for the anchoring the constraints
    public func constraintsPinned(toView view:UIView) -> [NSLayoutConstraint] {
        return [topAnchor.constraint(equalTo: view.topAnchor),
        bottomAnchor.constraint(equalTo: view.bottomAnchor),
        leadingAnchor.constraint(equalTo: view.leadingAnchor),
        trailingAnchor.constraint(equalTo: view.trailingAnchor)]
    }

}


extension UIView {
    
    /// Animate a bounce effect on the view.
    public func bounce(duration:TimeInterval = 0.6, scales:[CGFloat] = [0.60,1.1,0.9,1]) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.duration = duration
        bounceAnimation.values = scales
        let f = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        bounceAnimation.timingFunctions = scales.map({ (_) -> CAMediaTimingFunction in return f })
        bounceAnimation.isRemovedOnCompletion = false
        layer.add(bounceAnimation, forKey: "bounce")
    }
    
    @available(iOS 10.0, tvOS 10, *)
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
    @available(iOS 10.0, tvOS 10, *)
    public func fadeOut(completion:CompletionBlock? = nil) {
        fade(to: 0, completion: completion)
    }
    
    /// Animate the fade in the view.
    @available(iOS 10.0, tvOS 10, *)
    public func fadeIn(completion:CompletionBlock? = nil) {
        fade(to: 1, completion: completion)
    }
    
    public func shake(dx:CGFloat = 10) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - dx, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + dx, y: center.y))
        layer.add(animation, forKey: "shake")
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
    
    /// Returns a black color with a modified alpha component. Useful when creating
    /// fades or overlays with opacity.
    ///
    /// - parameter alpha: The opacity value (0.0 to 1.0)
    public convenience init(blackWithAlpha alpha:CGFloat) {
        self.init(red: 0, green: 0, blue: 0, alpha: alpha)
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
        ModernTableCell.register(withTableView: tableView)
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
        return ModernTableCell.dequeueReusableCell(inTableView: tableView)
    }
}

open class ModernCollectionController : ModernViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        ModernCollectionCell.register(withCollectionView: collectionView)
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
        return ModernCollectionCell.dequeueReusableCell(inCollectionView: collectionView, forIndexPath: indexPath)
    }
    
    
}

@available(*, deprecated, renamed: "ModernTableCell", message: "This class has been deprecated in favor of ModernTableCell.")
open class ReusableTableCell : ModernTableCell {}

@available(*, deprecated, renamed: "ModernCollectionCell", message: "This class has been deprecated in favor of ModernCollectionCell.")
open class ReusableCollectionCell : ModernCollectionCell {}

@available(*, deprecated, renamed: "ModernHeaderFooterView", message: "This class has been deprecated in favor of ModernHeaderFooterView.")
open class ReusableHeaderFooterView : ModernHeaderFooterView {}
