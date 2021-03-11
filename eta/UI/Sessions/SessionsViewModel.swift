//
//  Created by Lofionic ©2021
//

import Firebase
import RxCocoa
import RxSwift

final class SessionsViewModel: ViewModel {
    
    let isShowingShareView: Driver<Bool>
    let sessionsEvents: Driver<DatabaseEvent<Session>>
    
    var showUserMenuHandler: () -> Void = {}
    var embedShareViewControllerHandler: () -> UIViewController? = { nil }
    
    let authorizationService: AuthorizationService
    let databaseService: DatabaseService
    let theme: Theme
    
    private let isShowingShareViewRelay = BehaviorRelay(value: false)
    private let sessionsEventsRelay = PublishRelay<DatabaseEvent<Session>>()
    
    private let disposeBag = DisposeBag()
    
    init(authorizationService: AuthorizationService, databaseService: DatabaseService, theme: Theme = Theme.light) {
        self.authorizationService = authorizationService
        self.databaseService = databaseService
        self.theme = theme
        
        isShowingShareView = isShowingShareViewRelay.asDriver()
        sessionsEvents = sessionsEventsRelay
            .do(onNext: {
                print(String(describing: $0))
            })
            .asDriver(onErrorDriveWith: .empty())
        
        subscribeToSessions()
    }
    
    func subscribeToSessions() {
        guard let user = authorizationService.currentUser else { return }
        databaseService
            .sessions(userIdentifier: user.uid)
            .subscribe(onNext: { [weak self] event in
                self?.sessionsEventsRelay.accept(event)
            })
            .disposed(by: disposeBag)
    }
    
    func didTapUserButton() {
        showUserMenuHandler()
    }
    
    func setShowingShareView(_ showingShareView: Bool) {
        isShowingShareViewRelay.accept(showingShareView)
    }
}
