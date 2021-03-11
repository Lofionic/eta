//
//  Created by Lofionic ©2021
//

import RxSwift
import RxCocoa

enum AuthenticationUserStatus: Int {
    case existingUser
    case newUser
}

enum AuthenticationFirstResponder {
    case email
    case password
}

private extension AuthenticationUserStatus {
    var passwordFieldTextContentType: UITextContentType {
        switch self {
        case .existingUser: return .password
        case .newUser: return .newPassword
        }
    }
}

class AuthenticationViewModel: ViewModel {
    
    let strings = Strings()
    let authorizationService: AuthorizationService
    let theme: Theme
   
    let isContinueEnabled: Driver<Bool>
    let isWorking: Driver<Bool>
    let passwordRelayTextContentType: Driver<UITextContentType>
     
    let userStatus = BehaviorRelay<AuthenticationUserStatus>(value: .existingUser)
    let emailRelay = BehaviorRelay<Email?>(value: "test@test.com")
    let passwordRelay = BehaviorRelay<Password?>(value: "123456")
    
    let setFirstResponder: Driver<AuthenticationFirstResponder>
    
    var didAuthorizeHandler: () -> Void = {}
    
    private let isWorkingRelay = BehaviorRelay<Bool>(value: false)
    private let passwordRelayTextContentTypeRelay = BehaviorRelay<UITextContentType>(value: .password)
    private let setFirstResponderRelay = PublishRelay<AuthenticationFirstResponder>()
    
    private let disposeBag = DisposeBag()
    
    init(authorizationService: AuthorizationService, theme: Theme = Theme.light) {
        self.authorizationService = authorizationService
        self.theme = theme
        
        let isEmailValid = emailRelay
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .regex(Constants.emailRegex)
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
        passwordRelayTextContentType = passwordRelayTextContentTypeRelay.asDriver()
        
        setFirstResponder = setFirstResponderRelay.asDriver(onErrorDriveWith: .never())
        
        userStatus.subscribe(onNext: { [weak self] userStatus in
            let textContentType: [UITextContentType] = [.password, .newPassword]
            self?.passwordRelayTextContentTypeRelay.accept(textContentType[userStatus.rawValue])
        }).disposed(by: disposeBag)
        
        authorizationService.stateDidChange.subscribe(onNext: { [weak self] user in
            if user != nil {
                self?.didAuthorizeHandler()
            }
        }).disposed(by: disposeBag)
    }
}

extension AuthenticationViewModel {
    func `continue`() {
        print("Username: \(String(describing:emailRelay.value))")
        print("Password: \(String(describing:passwordRelay.value))")
        
        switch userStatus.value {
        case .existingUser:
            signIn(withEmail: emailRelay.value!, password: passwordRelay.value!)
        case .newUser:
            createUser(withEmail: emailRelay.value!, password: passwordRelay.value!)
        }
    }
    
    private func signIn(withEmail email: Email, password: Password) {
        performOperation(authorizationService.signIn(withEmail: email, password: password))
    }
    
    private func createUser(withEmail email: Email, password: Password) {
        performOperation(authorizationService.createUser(withEmail: email, password: password))
    }
    
    private func performOperation(_ operation: Single<User>) {
        operation
            .do(onSubscribe: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(true)
            })
            .subscribe(onSuccess: { [weak isWorkingRelay] _ in
                isWorkingRelay?.accept(false)
            }, onFailure: { [weak self] error in
                self?.isWorkingRelay.accept(false)
                self?.operationDidFail(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func operationDidFail(_ error: Error) {
        print(error)
		passwordRelay.accept(nil)
		setFirstResponderRelay.accept(.password)
    }
}

extension AuthenticationViewModel {
    struct Strings {
        let newUser = "New user"
        let existingUser = "Existing user"
        
        let emailAddress = "Email"
        let password = "Password"
        
        let signIn = "Sign In"
    }
	
	struct Constants {
		static let emailRegex = #"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])"#
	}
}
