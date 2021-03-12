//
//  RegisterViewContreoller.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

import RxCocoa
import RxSwift

final class RegisterViewController: UIViewController, StoryboardViewController {
    static var storyboardIdentifier = "Register"
    var viewModel: RegisterViewModel!
    
    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var continueButton: Button!
    
    @IBOutlet private var dismissButton: UIButton!
    @IBOutlet private var scrollingBackground: ScrollingBackground!
    @IBOutlet private var avoidKeyboardConstraint: NSLayoutConstraint!

    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        scrollingBackground.image = UIImage(named: "ScrollingBackground/Grey")
        
        setupStyling()
        setupStrings()
        
        addBinds()
        
        registerForKeyboardNotifications()
    }
    
    private func setupStyling() {
        let theme = viewModel.theme
        view.tintColor = theme.colors.tint
        
        emailTextField.font = theme.fonts.body
        passwordTextField.font = theme.fonts.body
        
    }
    
    private func setupStrings() {
        emailTextField.placeholder = viewModel.strings.emailAddress
        passwordTextField.placeholder = viewModel.strings.password
        
        continueButton.setTitle(viewModel.strings.continue, for: .normal)
    }
    
    private func addBinds() {
        disposeBag.insert([
            emailTextField.rx.text <-> viewModel.email,
            passwordTextField.rx.text <-> viewModel.password,
            
            viewModel.continueEnabled.drive(continueButton.rx.isEnabled),
            viewModel.isWorking.drive(continueButton.rx.isAnimatingActivityIndicator),
            
            viewModel.isWorking.not().drive(emailTextField.rx.isEnabled),
            viewModel.isWorking.not().drive(passwordTextField.rx.isEnabled),
            
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollingBackground.resumeScrolling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollingBackground.pauseScrolling()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        scrollingBackground.image = UIImage(named: "ScrollingBackground/Grey")
    }
}

private extension RegisterViewController {
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

extension RegisterViewController {
    @IBAction func didTapContinue(_ sender: Any) {
        viewModel.continue()
    }
    
    @IBAction func didTapDismiss(_ sender: Any) {
        viewModel.dismiss()
    }
}
