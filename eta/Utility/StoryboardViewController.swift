//
//  StoryboardViewController.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import UIKit

protocol ViewController {
    associatedtype T: ViewModel
    
    var viewModel: T! { get set }
}

protocol ViewModel {}

protocol StoryboardViewController: ViewController {
    static var storyboardIdentifier: String { get }
    static func instantiateFromStoryboard(_ storyboard: UIStoryboard) -> Self
}

extension StoryboardViewController {
    static func instantiateFromStoryboard(_ storyboard: UIStoryboard) -> Self {
        return storyboard.instantiateViewController(identifier: storyboardIdentifier) as! Self
    }
}
