//
//  Created by Lofionic ©2021
//


import UIKit

import RxCocoa
import RxSwift

class AuthenticationViewController: UIViewController, StoryboardViewController {
    
    static let storyboardIdentifier = "Authentication"
    
    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var continueButton: Button!
    @IBOutlet private var contentView: UIView!
    
    var viewModel: AuthenticationViewModel!
    
    private(set) lazy var keyboardHeightConstraint = keyboardLayoutGuide.heightAnchor.constraint(equalToConstant: 0)
    let keyboardLayoutGuide = UILayoutGuide()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        registerForKeyboardNotifications()
        
        view.addLayoutGuide(keyboardLayoutGuide)
        NSLayoutConstraint.activate([
            keyboardHeightConstraint,
            keyboardLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
        ])
        
        setBinds()
        setStrings()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        emailTextField.clear()
        passwordTextField.clear()
    }
}

private extension AuthenticationViewController {
    private func registerForKeyboardNotifications() {
        let notifications = NotificationCenter.default
        notifications.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard
                let self = self,
                let keyboardRect = notification.keyboardRect,
                let animationDuration = notification.keyboardAnimationDuration else
            {
                return
            }
            self.keyboardHeightConstraint.constant = keyboardRect.height
            UIView.animate(withDuration: animationDuration) {
                self.view.layoutIfNeeded()
            }
        }
        
        notifications.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] notification in
            guard
                let self = self,
                let animationDuration = notification.keyboardAnimationDuration else
            {
                return
            }
            
            self.keyboardHeightConstraint.constant = 0
            UIView.animate(withDuration: animationDuration) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

private extension AuthenticationViewController {
    @IBAction func didTapContinue(_ sender: Any) {
        viewModel.continue()
    }
}

private extension AuthenticationViewController {
    func setBinds() {
        disposeBag.insert([
            segmentedControl.rx.selectedSegmentIndex
                .map { AuthenticationUserStatus(rawValue: $0)! }
                .bind(to: viewModel.userStatus),
            
            emailTextField.rx.text <-> viewModel.emailRelay,
            passwordTextField.rx.text <-> viewModel.passwordRelay,
            
            viewModel.isContinueEnabled.drive(continueButton.rx.isEnabled),
            viewModel.isWorking.drive(continueButton.rx.isAnimatingActivityIndicator),
            
            viewModel.isWorking.not().drive(emailTextField.rx.isEnabled),
            viewModel.isWorking.not().drive(passwordTextField.rx.isEnabled),
            viewModel.isWorking.not().drive(segmentedControl.rx.isEnabled),
            
            viewModel.setFirstResponder.drive(onNext: { [weak self] firstResponder in
                guard let self = self else { return }
                switch firstResponder {
                case .email:
                    self.emailTextField.becomeFirstResponder()
                case .password:
                    self.passwordTextField.becomeFirstResponder()
                }
            })
        ])
    }
    
    func setStrings() {
        let strings = viewModel.strings
        segmentedControl.setTitle(strings.existingUser, forSegmentAt: 0)
        segmentedControl.setTitle(strings.newUser, forSegmentAt: 1)
        emailTextField.placeholder = strings.emailAddress
        passwordTextField.placeholder = strings.password
        continueButton.setTitle(strings.continue, for: .normal)
    }
}

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
            return true
        }
        
        if textField == passwordTextField {
            viewModel.continue()
            return true
        }
        return false
    }
}

extension UITextField {
    func clear() {
        text = nil
        sendActions(for: .allEditingEvents)
    }
}

private extension Notification {

    var keyboardAnimationDuration: TimeInterval? {
        (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
    }

    var keyboardRect: CGRect? {
        userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    }
}
