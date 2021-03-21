//
//  RegisterViewModel.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import RxCocoa
import RxSwift

final class RegisterViewModel: ViewModel {
    
    let email = BehaviorRelay<String?>(value: nil)
    let password = BehaviorRelay<String?>(value: nil)
    
    let emailValid: Driver<Bool>
    let passwordValid: Driver<Bool>
    let continueEnabled: Driver<Bool>
    
    let isWorking: Driver<Bool>
    let setFirstResponder: Driver<AuthenticationFirstResponder>
    
    var registerHandler: (UserIdentifier?) -> Void = { _ in }
    var dismissHandler: () -> Void = {}
    
    let theme: Theme
    let strings = RegisterStrings()
    
    private let isWorkingRelay = BehaviorRelay(value: false)
    private let setFirstResponderRelay = PublishRelay<AuthenticationFirstResponder>()
    
    private let authorizationService: AuthorizationService
    private let cloudService: CloudService
    
    private let disposeBag = DisposeBag()
    
    init(
        authorizationService: AuthorizationService,
        cloudService: CloudService,
        theme: Theme = Theme.light)
    {
        self.authorizationService = authorizationService
        self.cloudService = cloudService
        self.theme = theme
        
        emailValid = email
			.observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
			.lowercased()
			.regex(NSRegularExpression.email)
			.subscribe(on: MainScheduler.instance)
			.map { email -> Bool in
				if let email = email, !email.isEmpty {
					return true
				}
				return false
			}
			.asDriver(onErrorJustReturn: false)
        
        passwordValid = password
            .isValid(NSRegularExpression.password)
            .asDriver(onErrorJustReturn: false)
        
        continueEnabled = Driver
            .combineLatest(emailValid, passwordValid)
            .map { $0 && $1 }
        
        isWorking = isWorkingRelay.asDriver().distinctUntilChanged()
        setFirstResponder = setFirstResponderRelay.asDriver(onErrorDriveWith: .never())
    }
    
    func didTapContinue() {
        //
    }
    
    func dismiss() {
        dismissHandler()
    }
}

extension RegisterViewModel {
    func `continue`() {
        register(withEmail: email.value!, password: password.value!)
    }
    
    private func register(withEmail email: Email, password: Password) {
        authorizationService.createUser(withEmail: email, password: password)
            .do(onSubscribe: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(true)
            })
            .flatMap { [weak self] userIdentifier -> Single<UserIdentifier?> in
                guard let self = self else { return .never() }
                return self.cloudService.registerUser(userIdentifier, email: email)
            }
            .subscribe(onSuccess: { [weak self] userIdentifier in
                self?.isWorkingRelay.accept(false)
                self?.registerHandler(userIdentifier)
            }, onFailure: { [weak self] error in
                self?.isWorkingRelay.accept(false)
                self?.registerDidFail(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func registerDidFail(_ error: Error) {
        print(error)
        email.accept(nil)
        password.accept(nil)
        setFirstResponderRelay.accept(.password)
    }
}

struct RegisterStrings {
    let emailAddress = "Email"
    let password = "Password"
    
    let signIn = "Sign In"
    let signUp = "Sign Up"
    
    let `continue` = "Continue"
}
