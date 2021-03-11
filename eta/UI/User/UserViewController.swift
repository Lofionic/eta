//
//  UserViewController.swift
//  eta
//
//  Created by Chris Rivers on 07/03/2021.
//

import UIKit

import RxCocoa
import RxSwift

final class UserViewController: UIViewController, StoryboardViewController {
    
    static var storyboardIdentifier = "User"
    
    var viewModel: UserViewModel!
    
    @IBAction func didTapSignOut() {
        presentingViewController?.dismiss(animated: true)
        viewModel.signOut()
    }
}
