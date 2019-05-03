//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//


import UIKit

/// A protocol that allows UIViewControllers to be easily instantiable through a storyboard.
public protocol StoryboardInstantiable {
    
    /// The string used as "Storyboard Id" in the Storyboard that identifies
    /// this controller. It is recommended that the "Storyboard Id" is the name of the
    /// controller class (ex. MyViewController). This will allow for the default implementation of
    /// this protocol to take advantage of matching classes with Storyboard controllers.
    static var storyboardIdentifier:String { get }
    /// The base name of the storyboard file. (Ex. "Main" for "Main.storyboard")
    static var storyboardName:String { get }
    
    /// Instantiate a new instance of this view controller class from a storyboard.
    ///
    /// - parameter storyboardName: The string name of the storyboard that contains this controller. (Ex. "Main" for "Main.storyboard")
    /// - parameter bundle: The bundle where the storyboard file is contained. Defaults to main bundle.
    ///  storyboardIdentifier: The "Storyboard Id" to use when looking up the controller in the storyboard file.
    /// - returns: An instance of this view controller instantiaged from its storyboard
    static func storyboardController(_ storyboardName:String, inBundle bundle:Bundle?, withIdentifier storyboardIdentifier: String) -> Self?
}

extension StoryboardInstantiable where Self: UIViewController {
    
    /// The string of the name of the Storyboard file which contains this controller. Defaults to 'Main' (which maps to 'Main.storyboard').
    public static var storyboardName:String { return "Main" }
    
    /// Returns the string that is mapped as the "Storyboard Id" in the Storyboard that identifies this controller. The default
    /// value returns the name of the class. It is recommended that the "Storyboard Id" is the name of the
    /// controller class (ex. MyViewController). This will allow for the default implementation of
    /// this protocol to take advantage of matching classes with Storyboard controllers.
    public static var storyboardIdentifier:String {
        return String(describing: Self.self)
    }
    
    /// Get an instance of this view controller class instantiated from it's storyboard file.
    public static var storyboardController:Self? {
        return storyboardController(storyboardName)
    }
    
    /// Instantiate a new instance of this view controller class from a storyboard.
    ///
    /// - parameter storyboardName: The string name of the storyboard that contains this controller. (Ex. "Main" for "Main.storyboard")
    /// - parameter bundle: The bundle where the storyboard file is contained. Defaults to main bundle.
    ///  storyboardIdentifier: The "Storyboard Id" to use when looking up the controller in the storyboard file.
    /// - returns: An instance of this view controller instantiaged from its storyboard
    public static func storyboardController(_ storyboardName: String, inBundle bundle:Bundle? = nil, withIdentifier storyboardIdentifier: String = Self.storyboardIdentifier) -> Self? {
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        return storyboardController(storyboard, withIdentifier: storyboardIdentifier)
    }
    
    /// Instantiate a new instance of this view controller from a storyboard using a storyboard identifier.
    ///
    /// - parameter storyboard: The storyboard object to find the storyboard.
    /// - parameter storyboardIdentifier: The "Storyboard Id" that represents this
    ///   controller in the storyboard. Defaults to the class property `storyboardIdentifier`
    /// - returns: A new instance of the view controller instantiated from its storyboard
    public static func storyboardController(_ storyboard: UIStoryboard?, withIdentifier storyboardIdentifier: String = Self.storyboardIdentifier) -> Self? {
        guard let storyboard = storyboard else { return nil }
        return storyboard.instantiateViewController(withIdentifier: self.storyboardIdentifier) as? Self
    }
    
}

/// A protocol that defines an string enum of `SegueIdentifier`, to make
/// having named segues a bit cleaner. This allows for type safety when
/// performing segues. See `SegueHandlerType.SegueIdentifier`.
/// - SeeAlso: [SegueIdentifier]
public protocol SegueHandlerType {
    /**
    This enum, whose raw representation should be strings, should
    list all segue names as defined in your storyboard. This will make it
    better when performing segues using the helper methods.
 
    ## Example
    Assume an example where a UIViewController in a storyboard has two defined segues to other
     controlleres. The segue names listed in the storyboards are 'segueToMusic' and 'segueToVideos'.
     Instead of using strings in your method calls, you can implement the `SegueHandlerType` protocol,
     and define the segues in the `SegueIdentifier` enum.
     
    ````
    class MyViewController : UIViewController, SegueHandlerType
    {
        // defines segues from this controller to other ones
        enum SegueIdentifier: String {
            case segueToMusic
            case segueToVideos
        }
    }
    ````
     
     When this is done, you can perform segues with better type safety instead of arbitrary strings:
    ````
    performSegueIdentifier(.segueToMusic, sender: self)
    ````
    */
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    // Perform a segue using a `SegueIdentifier`. See `SegueHandlerType` protocol.
    /// ## Example
    ///     performSegueIdentifier(.segueToNext, sender: self)
    /// - parameter to: The SegueIdentifier enum defined in the current controller scope.
    /// - parameter sender: The object that you want to use to initiate the segue. This object is
    /// made available for informational purposes during the actual segue.
    public func segue(to: SegueIdentifier, sender: Any? = nil) {
        performSegue(withIdentifier: to.rawValue, sender: sender)
    }
    
    @available(*, deprecated, message: "This method has been renamed to segue(to:).")
    public func performSegueIdentifier(_ segueIdentifier: SegueIdentifier, sender: Any?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
    

}

/// A protocol that combines `StoryboardInstantiable` and `SegueHandlerType`. Generally,
/// this is the protocol UIViewControllers should use when wanting to be instantiated from
/// storyboards as well as having defined segues between storyboard controllers.
public protocol StoryboardConformance: StoryboardInstantiable, SegueHandlerType {}
