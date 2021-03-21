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
    let cloudService: CloudService
    let userService: UserService
    let pendingSessionsController: PendingSessionController
    let theme: Theme
    
    private let isShowingShareViewRelay = BehaviorRelay(value: false)
    private let sessionsEventsRelay = PublishRelay<DataEvent<Session>>()
    
    private let disposeBag = DisposeBag()
    
    init(
        authorizationService: AuthorizationService,
        sessionService: SessionService,
        userService: UserService,
        cloudService: CloudService,
        pendingSessionsController: PendingSessionController = .shared,
        theme: Theme = Theme.light)
    {
        self.authorizationService = authorizationService
        self.sessionService = sessionService
        self.cloudService = cloudService
        self.userService = userService
        self.pendingSessionsController = pendingSessionsController
        self.theme = theme
        
        isShowingShareView = isShowingShareViewRelay.asDriver()
        sessionsEvents = sessionsEventsRelay
            .do(onNext: {
                print(String(describing: $0))
            })
            .asDriver(onErrorDriveWith: .empty())
        
        subscribeToPendingSessions()
        subscribeToSessions()
    }
    
    private func subscribeToSessions() {
        guard let userIdentifier = authorizationService.currentUser else { return }
        sessionService
            .sessionEvents(subscriberIdentifier: userIdentifier, events: [.add, .remove])
            .subscribe(onNext: { [weak self] event in
                self?.sessionsEventsRelay.accept(event)
            })
            .disposed(by: disposeBag)
    }
    
    private func subscribeToPendingSessions() {
        PendingSessionController.shared.rx
            .pendingSessions()
            .flatMap { [weak self] sessionIdentifier -> Completable in
                guard let self = self else {
                    return .never()
                }
                return self.cloudService
                    .authorize()
                    .andThen(self.cloudService.joinSession(sessionIdentifier: sessionIdentifier))
                    .do(onSubscribe: { print("onSubscribe joinSession")}, onSubscribed: { print("onSubscribed joinSession")})
            }
            .do(
                onSubscribe: { print("onSubscribe pendingSessions")},
                onSubscribed: { print("onSubscribed pendingSessions") })
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func didTapUserButton() {
        showUserMenuHandler()
    }
    
    func setShowingShareView(_ showingShareView: Bool) {
        isShowingShareViewRelay.accept(showingShareView)
    }
    
    func viewModelForSession(_ session: Session) -> SessionCellViewModel {
        let viewModel = SessionCellViewModel(
            sessionIdentifier: session.identifier,
            sessionService: sessionService,
            userService: userService,
            cloudService: cloudService)
        return viewModel
    }
}
