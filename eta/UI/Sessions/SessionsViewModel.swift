//
//  Created by Lofionic ©2021
//

import Firebase
import RxCocoa
import RxSwift

final class SessionsViewModel: ViewModel {
    
    let isShowingShareView: Driver<Bool>
    let sessionsEvents: Driver<DataEvent<Session>>
    
    var showUserMenuHandler: () -> Void = {}
    var embedShareViewControllerHandler: () -> UIViewController? = { nil }
    
    let authorizationService: AuthorizationService
    let sessionService: SessionService
    let theme: Theme
    
    private let isShowingShareViewRelay = BehaviorRelay(value: false)
    private let sessionsEventsRelay = PublishRelay<DataEvent<Session>>()
    
    private let disposeBag = DisposeBag()
    
    init(authorizationService: AuthorizationService, sessionService: SessionService, theme: Theme = Theme.light) {
        self.authorizationService = authorizationService
        self.sessionService = sessionService
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
        guard let userIdentifier = authorizationService.currentUser else { return }
        sessionService
            .sessions(userIdentifier: userIdentifier)
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
