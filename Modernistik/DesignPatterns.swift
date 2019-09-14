//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import UIKit

/** Protocol that requires the implementor to have a `reuseIdentifier` field.
    This is normally implemented by items that will go through a recycling phase like `UITableViewCell` or `UICollectionViewCell`.
 # Discussion:
 We have defined an extension to this protocol which automatically returns the name of the class as the
 default implementation of this property.
 */
public protocol ReusableType {
    static var reuseIdentifier: String { get }
}

extension ReusableType {
    /// Return the reuseIdentifier for this object. By default it is their class name.
    public static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

/// An object that has a rawValue type that returns an Int.
public protocol IntRepresentable {
    var rawValue: Int { get }
}

/// An object that has a rawValue type that returns a String.
public protocol StringRepresentable {
    var rawValue: String { get }
}

/** Basic protocol for following a standard lifecycle of calls for UIView subclasses. This
 is the starting point for most view classes. Normally, you do not have to conform to this protocol
 and you would use one of the concrete subclasses. The three methods that need implementation are:

 ```
 func setupView() {
    // code to setup subviews and layout
 }

 func updateInterface() {
    // code to update the interface
 }

 func prepareForReuse() {
    // code to reset the view.
    // this method is already present
    // in UITableViewCell and UICollectionViewCell
 }
 ```
 */
public protocol ModernViewConformance: AnyObject {
    /// This method, called once in the view's lifecycle, should implement
    /// setting up the view's children in the parent's view. This method will be called
    /// when the view is instantiated programmatically or through a storyboard.
    func setupView()

    /// This method should implement setting up the autolayout constraints, if any, for the subviews that
    /// were added in `setupView()`. This method should only be called once in the view's lifecycle, normally before
    /// a layout pass.
    ///
    /// - note: The default implementation does nothing. Do not call `setNeedsUpdateConstraints()` inside
    /// your implementation. Calling `setNeedsUpdateConstraints()` may schedule another update pass, creating a feedback loop.
    /// - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
    /// call the super implementation.
    func setupConstraints()

    /// This method, should implement changes in the view's interface.
    ///
    /// - note: The default implementation does nothing.
    func updateInterface()

    /// This method, should implement resetting any view properties or subviews
    /// when it is going through view recycling, for example, cells in a table view.
    /// - note: The default implementation does nothing.
    func prepareForReuse()
}

/** Basic protocol that most application controllers should adopt. Normally you would not implement
 this protocol and instead subclass `ModernViewController` which provides extension and functionality.
 This protocol defines two methods:
 ```
 func setupConstraints() {
    // code to setup view constraints
 }

 func updateInterface() {
 // code to update the interface based on some state or action change.
 }
 ```
 */
public protocol ModernControllerConformance: AnyObject {
    /**
     This method will be called once as part of the view controller
     lifecycle, in order for the controller to setup its autolayout
     constraints and add them to the view controller's view property.

     - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
     call super.
     */
    func setupConstraints()

    /// This method, should implement changes in the controller's view.
    ///
    /// The default implmentation of this method does nothing.
    func updateInterface()
}

// Default implementations
extension ModernControllerConformance where Self: UIViewController {
    public func setupConstraints() {}
    public func updateInterface() {}
}

/** Provides a standard interface to get recommended proportional heights based on
 different sized devices or viewports. The idea behind this pattern is in defining an aspect
 ratio that this view prefers. By adopting this protocol and setting the `aspectRatio`, several
 extensions will make it easier to determine correct sizes utilizing this value.
 # Example

 ```
 // Adopt the protocol
 class MyView : ModernView, ProportionalViewMetrics {
    static var aspectRatio:CGFloat = 1920/1080
 }

 // Using the aspect ratio, we can calculate proper sizes
 MyView.recommendedHeight(forWidth: 640) //-> 360
 ```
 */
public protocol ProportionalViewMetrics {
    /// The recommended height for this view. The default implementation is the width of
    /// the UIScreen.mainScreen() divided by the aspectRatio.
    static var recommendedHeight: CGFloat { get }

    /**
      Returns the height based on the aspectRatio for a given width. By default, this is
      is calculated by width/aspectRatio. The default implementation
      returns the `recommendedHeight` value.
      # Example

      ```
      // Assume subclass
      class MyView : ModernView, ProportionalViewMetrics {
         static var aspectRatio:CGFloat = 1920/1080
      }

      // Using the aspect ratio, we can calculate proper sizes
      MyView.recommendedHeight(forWidth: 640) //-> 360
      ```
     - parameter forWidth: the width to use when calculating the height.
     - returns: The recommended height based on input width.
     */
    static func recommendedHeight(forWidth: CGFloat) -> CGFloat

    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    static var aspectRatio: CGFloat { get }
    /// Returns 1/aspectRatio (height/width).
    static var inverseAspectRatio: CGFloat { get }
}

extension ProportionalViewMetrics {
    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    public static var aspectRatio: CGFloat { return 1 }
    /// Returns `1/aspectRatio` (height/width).
    public static var inverseAspectRatio: CGFloat { return 1 / aspectRatio }
    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    public static var recommendedHeight: CGFloat {
        return UIScreen.main.bounds.width / aspectRatio
    }

    /// The recommended height for the given with, with respect to the current
    /// aspectRatio (width/height).
    /// - parameter width: The width to use to calculate the height.
    public static func recommendedHeight(forWidth width: CGFloat) -> CGFloat {
        return width / aspectRatio
    }

    /// Returns a size with a recommended height based on the supplied width.
    /// Shorthand for:
    /// ```
    /// CGSize(width: width, height: recommendedHeight(forWidth: width))
    /// ```
    /// - parameter width: The width to use to calculate the height.
    public static func recommendedSize(forWidth width: CGFloat) -> CGSize {
        return CGSize(width: width, height: recommendedHeight(forWidth: width))
    }
}

extension ReusableType where Self: UITableViewCell {
    public static func register(with tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        tableView.register(Self.self, forCellReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableCell(in tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? Self {
            return cell
        }
        assertionFailure("TableView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }

    public static func dequeueReusableCell(inTableView tableView: UITableView, forIndexPath indexPath: IndexPath) -> Self {
        let ident = String(describing: Self.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: ident, for: indexPath) as? Self {
            return cell
        }
        assertionFailure("TableView misconfigured! Failed dequeueing of \(ident)")
        return Self()
    }
}

extension ReusableType where Self: UITableViewHeaderFooterView {
    public static func register(with tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        tableView.register(Self.self, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableHeaderFooterView(in tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? Self {
            return cell
        }
        assertionFailure("TableHeaderFooterView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }

    public static func dequeueReusableHeaderFooterView(in tableView: UITableView) -> Self {
        let ident = String(describing: Self.self)

        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ident) as? Self {
            return cell
        }
        assertionFailure("TableHeaderFooterView misconfigured! Failed dequeueing of \(ident)")
        return Self()
    }
}

extension ReusableType where Self: UICollectionViewCell {
    public static func register(with collectionView: UICollectionView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        collectionView.register(Self.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableCell(in collectionView: UICollectionView, for indexPath: IndexPath, reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? Self {
            return cell
        }
        assertionFailure("CollectionView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }
}

extension ReusableType where Self: UICollectionReusableView {
    public static func register(with collectionView: UICollectionView, forSupplementaryViewOfKind kind: String, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        collectionView.register(Self.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableSupplementaryView(ofKind elementKind: String, in collectionView: UICollectionView, for indexPath: IndexPath, reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: reuseIdentifier, for: indexPath) as? Self {
            return view
        }
        assertionFailure("UICollectionReusableView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }
}

/// Provides an interface for views who need to be loaded from nib/xib files.
public protocol Nibbed {
    static var nib: UINib { get }
}

extension Nibbed where Self: ReusableType, Self: UIView {
    /// Load a UINib object for the current view based on the view name.
    public static var nib: UINib {
        return UINib(nibName: String(describing: Self.self), bundle: nil)
    }

    /// Load the proper view subclass from its corresponding nib/xib in the main bundle.
    public static func nibView(owner: AnyObject) -> Self {
        let ident = String(describing: Self.self)
        if let view = Bundle.main.loadNibNamed(ident, owner: owner, options: nil)?.first as? Self {
            return view
        }
        assertionFailure("Invalid Nib loading configuration for \(ident)")
        return Self()
    }
}

extension Nibbed where Self: UITableViewCell, Self: ReusableType {
    /// Registers the table cell class using the registered nib file.
    public static func registerNib(with tableView: UITableView) {
        tableView.register(Self.nib, forCellReuseIdentifier: String(describing: Self.self))
    }
}

extension Nibbed where Self: UICollectionViewCell, Self: ReusableType {
    /// Registers the collection cell class using the registered nib file.
    public static func registerNib(with collectionView: UICollectionView) {
        collectionView.register(Self.nib, forCellWithReuseIdentifier: String(describing: Self.self))
    }
}

open class ModernHeaderFooterView: UITableViewHeaderFooterView, ReusableType, ModernViewConformance {
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    @objc open func updateInterface() {}
}

/// Base view class that follows the general setup/update/reuse pattern when
/// either instantiating from nibs/storyboards or code. Because it implements
/// `ModernViewConformance`, it will properly call `setupView()` whether the view
/// is instantiated through an designated initializer, storyboard or nib.
open class ModernView: UIView, ModernViewConformance {
    @objc public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    @objc open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    /// This method should implement setting up the autolayout constraints, if any, for the subviews that
    /// were added in `setupView()`. This method is only called once in the view's lifecycle in `updateConstraints()`
    /// layout pass through an internal flag.
    ///
    /// - note: Do not call `setNeedsUpdateConstraints()` inside your implementation.
    /// Calling `setNeedsUpdateConstraints()` may schedule another update pass, creating a feedback loop.
    /// - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
    /// call the super implementation.
    @objc open func setupConstraints() {}

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {
        setNeedsDisplay()
    }

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}
}

/// Provides a base UITableViewCell class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernTableCell: UITableViewCell, ReusableType, ModernViewConformance {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true

    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    @objc open func updateInterface() {}
}

/// Provides a base UICollectionViewCell class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernCollectionCell: UICollectionViewCell, ReusableType, ModernViewConformance {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    @objc open func updateInterface() {}
}

/// Provides a base UILabel class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernLabel: UILabel, ModernViewConformance {
    public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() { text = nil }
}

/// Provides a base UIButton class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc. It also supports modifying the `minimumHitArea` property for
/// easily increasing the target tap frame.
open class ModernButton: UIButton, ModernViewConformance {
    public var minimumHitArea = CGSize.zero

    public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /// Alias for title(for: .normal) setter and getter.
    @objc open var title: String? {
        get {
            return title(for: .normal)
        }
        set {
            setTitle(newValue, for: .normal)
        }
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}

    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}

    @objc open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if minimumHitArea == CGSize.zero { return super.hitTest(point, with: event) }
        // need optimization
        // if the button is hidden/disabled/transparent it can't be hit
        if isHidden || !isUserInteractionEnabled || alpha < 0.01 {
            return nil
        }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}

/// Provides a base UIControl class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc. It also supports modifying the `minimumHitArea` property for
/// easily increasing the target tap frame.
open class ModernControl: UIControl, ModernViewConformance {
    public var minimumHitArea = CGSize.zero

    public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}

    @objc open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if minimumHitArea == CGSize.zero { return super.hitTest(point, with: event) }
        // need optimization
        // if the button is hidden/disabled/transparent it can't be hit
        if isHidden || !isUserInteractionEnabled || alpha < 0.01 {
            return nil
        }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}

/// Provides a base UITextField class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernTextField: UITextField, ModernViewConformance {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() { text = nil }
}

/// Provides a base UITextField class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernTextView: UITextView, ModernViewConformance {
    public init(autolayout _: Bool) {
        super.init(frame: .zero, textContainer: nil)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() { text = nil }
}

/// Provides a simple UIView that implements ModernViewConformance, which has an adjustable hit target area by modifying `minimumHitArea`, and allows for easily adding a block to be executed whenever the view is tapped.
open class TappableModernView: ModernView {
    public var minimumHitArea = CGSize.zero
    var _actionBlock: (() -> Void)?

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    open override func setupView() {
        super.setupView()
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    @objc open func tapped() {
        _actionBlock?()
    }

    open func tap(block: @escaping (() -> Void)) {
        _actionBlock = block
    }

    @objc open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if minimumHitArea == CGSize.zero { return super.hitTest(point, with: event) }
        // need optimization
        // if the button is hidden/disabled/transparent it can't be hit
        if isHidden || !isUserInteractionEnabled || alpha < 0.01 {
            return nil
        }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}

/// Provides a UIStackView that implements ModernViewConformance.
open class ModernStackView: UIStackView, ModernViewConformance {
    public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}
}
