//
//  RegisterViewModel.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import RxCocoa
import RxSwift

final class RegisterViewModel: ViewModel {
    
    var dismissHandler: () -> Void = {}
    
    let theme: Theme
    let strings = RegisterStrings()
    
    let email = BehaviorRelay<String?>(value: nil)
    let password = BehaviorRelay<String?>(value: nil)
    
    let emailValid: Driver<Bool>
    let passwordValid: Driver<Bool>
    let continueEnabled: Driver<Bool>
    
    let isWorking: Driver<Bool>
    private let isWorkingRelay = BehaviorRelay(value: false)
    
    let setFirstResponder: Driver<AuthenticationFirstResponder>
    private let setFirstResponderRelay = PublishRelay<AuthenticationFirstResponder>()
    
    let authorizationService: AuthorizationService
    let cloudService: CloudService
    
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
            .isValid(NSRegularExpression.email)
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
            .flatMapCompletable { [weak self] userIdentifier -> Completable in
                guard let self = self else { return .never() }
                return self.cloudService.registerUser(userIdentifier, email: email)
            }
            .subscribe(onCompleted: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(false)
            }, onError: { [weak self] error in
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
