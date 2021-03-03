//
//  Created by Lofionic ©2021
//

import RxCocoa
import RxSwift

final class SessionsViewModel: ViewModel {
    
    var showUserMenuHandler: () -> Void = {}
    
    let authorizationService: AuthorizationService
    
    init(authorizationService: AuthorizationService) {
        self.authorizationService = authorizationService
    }
    
    func didTapUserButton() {
        showUserMenuHandler()
    }
}
