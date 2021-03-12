//
//  UIViewController.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

extension UITraitCollection {
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return userInterfaceStyle == .dark
        } else {
            return false
        }
    }
}

extension Notification {    
    var keyboardAnimationDuration: TimeInterval? {
        (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    }
    
    var keyboardRect: CGRect? {
        userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    }
}
