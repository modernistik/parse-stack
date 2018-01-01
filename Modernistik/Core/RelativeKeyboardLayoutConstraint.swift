// The MIT License (MIT)
//
// Original James Tang
// Ported to Swift 3 : Anthony Persaud


import Foundation
import UIKit

/**
 An animated keyboard constraint that can be tied relative to another another view or layout guide. When the keyboard is invoked, it will animate
 the constraints in the window so that the keyboard smoothly transitions from visible to hidden.
 
 The first item is recommended to be the bottomLayoutGuide and the second view in the constraint
 should be the view that should move when the keyboard becomes presented or hidden.
 
 ### Example ###
 ````
 let keyboardConstraint = RelativeKeyboardLayoutConstraint(
                    item: bottomLayoutGuide,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: someView,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: 0)
 // whether you want an offset between the two views
 keyboardConstraint.offset = 10
 
 // You can turn off the animated transition.
 keyboardConstraint.animate = false
 ````
 */
final
public class RelativeKeyboardLayoutConstraint: NSLayoutConstraint {
    
    /// An offset between the keyboard (bottomLayoutGuide) and the target view.
    public var offset : CGFloat = 0
    
    /// Whether you want the keyboard to animate in and out.
    public var animate = true
    private var keyboardVisibleHeight : CGFloat = 0
    
    override public init() {
        super.init()
        setupConstraint()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupConstraint()
    }
    
    public func setupConstraint() {
        offset = constant
        
        NotificationCenter.default.addObserver(self, selector: #selector(RelativeKeyboardLayoutConstraint.keyboardWillShowNotification(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RelativeKeyboardLayoutConstraint.keyboardWillHideNotification(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func keyboardWillShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                let frame = frameValue.cgRectValue
                keyboardVisibleHeight = frame.size.height
            }
            
            updateConstant()
            guard animate else { UIApplication.shared.keyWindow?.setNeedsUpdateConstraints(); return }
            
            switch (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber, userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber) {
            case let (.some(duration), .some(curve)):
                
                let options = UIViewAnimationOptions(rawValue: curve.uintValue)
                
                UIView.animate(
                    withDuration: TimeInterval(duration.doubleValue),
                    delay: 0,
                    options: options,
                    animations: {
                        UIApplication.shared.keyWindow?.layoutIfNeeded()
                }, completion: nil)
            default:
                
                break
            }
            
        }
        
    }
    
    public func keyboardWillHideNotification(notification: NSNotification) {
        keyboardVisibleHeight = 0
        updateConstant()
        guard animate else { UIApplication.shared.keyWindow?.setNeedsUpdateConstraints(); return }
        
        if let userInfo = notification.userInfo {
            
            switch (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber, userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber) {
            case let (.some(duration), .some(curve)):
                let options = UIViewAnimationOptions(rawValue: curve.uintValue)
                
                UIView.animate(
                    withDuration: TimeInterval(duration.doubleValue),
                    delay: 0,
                    options: options,
                    animations: {
                        UIApplication.shared.keyWindow?.layoutIfNeeded()
                }, completion: nil)
            default:
                break
            }
        }
    }
    
    public func updateConstant() {
        constant = offset + keyboardVisibleHeight
    }
    
}
