//
//  Lofionic ©2021
//

import RxCocoa
import RxSwift

final class SharingViewModel: ViewModel {
    
    let eta: Driver<String>
    let subscriberUsername: Driver<String>
    
    var sharingEndedHandler: () -> Void = {}
    
    private let sessionIdentifier: SessionIdentifier
    private let sessionService: SessionService
    private let userService: UserService
    private let cloudService: CloudService
    
    private let etaSubject = BehaviorRelay<ETA?>(value: nil)
    private let subscriberSubject = BehaviorRelay<User?>(value: nil)
    
    private let disposeBag = DisposeBag()
    
    init(
        sessionIdentifier: SessionIdentifier,
        sessionService: SessionService,
        userService: UserService,
        cloudService: CloudService)
    {
        self.sessionIdentifier = sessionIdentifier
        self.sessionService = sessionService
        self.userService = userService
        self.cloudService = cloudService
        
        eta = etaSubject.asDriver().compactMap{
            guard let eta = $0 else { return "Unknown" }
            return DateComponentsFormatter.eta.string(from: eta.duration)
        }
        subscriberUsername = subscriberSubject.asDriver().compactMap { $0?.description ?? " " }
        
        setupSubscriptions()
    }
    
    func endSession() {
        cloudService
            .authorize()
            .andThen(cloudService.removeSession(sessionIdentifier: sessionIdentifier))
            .subscribe(onCompleted: { [weak self] in
                self?.sharingEndedHandler()
            }, onError: { error in
                print("Unable to remove session: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    private func setupSubscriptions() {
        sessionService
            .sessionEvents(sessionIdentifier: sessionIdentifier)
            .subscribe(onNext: { [weak self] session in
                self?.updateWithSession(session)
            }, onError: { error in
                print("Unable to update session: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    private func updateWithSession(_ session: Session) {
        etaSubject.accept(session.eta)
        guard let subscriberIdentifier = session.subscriberIdentifier else { return }
        _ = userService
            .getUser(subscriberIdentifier)
            .subscribe(onSuccess: { [weak self] user in
                guard session.subscriberIdentifier == user.identifier else { return }
                self?.subscriberSubject.accept(user)
            }, onFailure: { error in
                print("Could not get user: \(error)")
            })
    }
}

private extension User {
    
    var description: String? {
        if let username = username {
            return username
        }
        return email
    }
}
