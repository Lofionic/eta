//
//  UserViewModel.swift
//  eta
//
//  Created by Chris Rivers on 07/03/2021.
//

import RxCocoa
import RxSwift

final class UserViewModel: ViewModel {
    
    let userService: UserService
    let authorizationService: AuthorizationService
    
    let user: Driver<User?>
    
    private let userSubject = BehaviorRelay<User?>(value: nil)
    
    private let disposeBag = DisposeBag()
    
    init(userService: UserService, authorizationService: AuthorizationService) {
        self.userService = userService
        self.authorizationService = authorizationService
        
        user = userSubject.asDriver()
        getUserData()
    }
    
    private func getUserData() {
        guard let userIdentifier = authorizationService.currentUser else { return }
        
        userService.getUser(userIdentifier)
            .subscribe(onSuccess: { [weak self] user in
                self?.userSubject.accept(user)
            }, onFailure: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
    
    func signOut() {
        _ = authorizationService.signOut().subscribe()
    }
}
