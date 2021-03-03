//
//  UserViewModel.swift
//  eta
//
//  Created by Chris Rivers on 07/03/2021.
//

import RxCocoa
import RxSwift

final class UserViewModel: ViewModel {
    
    let authorizationService: AuthorizationService
    
    init(authorizationService: AuthorizationService) {
        self.authorizationService = authorizationService
    }
    
    func signOut() {
        _ = authorizationService.signOut().subscribe()
    }
}
