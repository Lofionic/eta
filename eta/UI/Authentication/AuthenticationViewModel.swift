//
//  Created by Lofionic ©2021
//

import RxSwift
import RxCocoa

enum AuthenticationFirstResponder {
    case email
    case password
}

class AuthenticationViewModel: ViewModel {
    
    let strings = AuthenticationStrings()
    let authorizationService: AuthorizationService
    let theme: Theme
    
    let isContinueEnabled: Driver<Bool>
    let isWorking: Driver<Bool>
    
    let emailRelay = BehaviorRelay<Email?>(value: nil)
    let passwordRelay = BehaviorRelay<Password?>(value: nil)
    
    let setFirstResponder: Driver<AuthenticationFirstResponder>
    
    var signInHandler: (UserIdentifier) -> Void = { _ in }
    var registerHandler: () -> Void = {}
    
    private let isWorkingRelay = BehaviorRelay<Bool>(value: false)
    private let setFirstResponderRelay = PublishRelay<AuthenticationFirstResponder>()
    
    private let disposeBag = DisposeBag()
    
    init(authorizationService: AuthorizationService, theme: Theme = Theme.light) {
        self.authorizationService = authorizationService
        self.theme = theme
        
        let isEmailValid = emailRelay
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
        
        let isPasswordValid = passwordRelay.map { password -> Bool in
            if let password = password, password.count > 5 {
                return true
            }
            return false
        }
        
        isContinueEnabled =
            Observable.combineLatest(isEmailValid, isPasswordValid, isWorkingRelay)
            .map {
                $0 && $1 && !$2
            }
            .asDriver(onErrorJustReturn: false)
        
        isWorking = isWorkingRelay.asDriver()
        
        setFirstResponder = setFirstResponderRelay.asDriver(onErrorDriveWith: .never())
        
//        authorizationService.stateDidChange.subscribe(onNext: { [weak self] user in
//            if user != nil {
//                self?.didAuthorizeHandler()
//            }
//        }).disposed(by: disposeBag)
    }
}

extension AuthenticationViewModel {
    func `continue`() {
        signIn(withEmail: emailRelay.value!, password: passwordRelay.value!)
    }
    
    func register() {
        registerHandler()
    }
    
    private func signIn(withEmail email: Email, password: Password) {
        authorizationService.signIn(withEmail: email, password: password)
            .do(onSubscribe: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(true)
            })
            .subscribe(onSuccess: { [weak self] user in
                self?.isWorkingRelay.accept(false)
                self?.signInHandler(user)
            }, onFailure: { [weak self] error in
                self?.isWorkingRelay.accept(false)
                self?.signInDidFail(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func signInDidFail(_ error: Error) {
        print(error)
        passwordRelay.accept(nil)
        setFirstResponderRelay.accept(.password)
    }
}

struct AuthenticationStrings {
    let emailAddress = "Email"
    let password = "Password"
    
    let signIn = "Sign In"
    let signUp = "Sign Up"
}
