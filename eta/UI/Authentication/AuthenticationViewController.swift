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
    
    @IBOutlet private var avoidKeyboardConstraint: NSLayoutConstraint!
    
    var viewModel: AuthenticationViewModel!
    
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        registerForKeyboardNotifications()
        
        setBinds()
        setStrings()
        setupStyling()
    }
    
    private func setupStyling() {
        let theme = viewModel.theme
        view.backgroundColor = UIColor.systemGray6
        view.tintColor = theme.colors.tint
        
        emailTextField.font = theme.fonts.body
        passwordTextField.font = theme.fonts.body
        
        segmentedControl.selectedSegmentTintColor = theme.colors.primary
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
        
        emailTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        emailTextField.clear()
//        passwordTextField.clear()
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
            self.avoidKeyboardConstraint.constant = keyboardRect.height
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
            
            self.avoidKeyboardConstraint.constant = 0
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
        continueButton.setTitle(strings.signIn, for: .normal)
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

extension AuthenticationViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard fromVC.isKind(of: Self.self) else { return nil }
        
        let continueFrame = continueButton.bounds
        let startingRect = CGRect(
            center: continueButton.convert(continueFrame.mid, to: view),
            size: CGSize(width: continueFrame.height, height: continueFrame.height))
        
        
        return IrisTransition(startRectangle: startingRect)
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
