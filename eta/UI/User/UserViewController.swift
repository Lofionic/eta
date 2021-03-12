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
    
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var signOutButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBinds()
    }
    
    private func addBinds() {
        viewModel.user.drive(onNext: { [weak self] user in
            guard let self = self, let user = user else { return }
            self.usernameLabel.text = user.username
            self.emailLabel.text = user.email
        }).disposed(by: disposeBag)
    }
    
    @IBAction func didTapSignOut() {
        presentingViewController?.dismiss(animated: true)
        viewModel.signOut()
    }
}
