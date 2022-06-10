//
//  Lofionic ©2021
//

import Foundation

import RxCocoa
import RxSwift

final class SessionCellViewModel: ViewModel {
    
    let user: Driver<User?>
    let username: Driver<String>
    let title: Driver<String>
    let eta: Driver<String>
    let isAuthorized: Driver<Bool>
    
    let sessionIdentifier: SessionIdentifier
    let sessionService: SessionService
    let userService: UserService
    let cloudService: CloudService
    
    let theme: Theme
    
    private let statusSubject = PublishSubject<SessionStatus>()
    
    private let userSubject = BehaviorRelay<User?>(value: nil)
    private let titleSubject = BehaviorRelay<String?>(value: nil)
    private let etaSubject = BehaviorRelay<String?>(value: nil)
    
    private let authorize = PublishSubject<Void>()
    
    private let disposeBag = DisposeBag()
    
    init(
        sessionIdentifier: SessionIdentifier,
        sessionService: SessionService,
        userService: UserService,
        cloudService: CloudService,
        theme: Theme = Theme.light)
    {
        self.sessionIdentifier = sessionIdentifier
        self.sessionService = sessionService
        self.userService = userService
        self.cloudService = cloudService
        self.theme = theme
        
        user = userSubject.asDriver()
        username = userSubject.map {
            if let user = $0 {
                return user.username ?? user.email
            }
            return " "
        }.asDriver(onErrorJustReturn: " ")
        
        title = titleSubject.asDriver().compactMap{ $0 ?? " " }
        eta = etaSubject.asDriver().compactMap{ $0 ?? " " }
        isAuthorized = statusSubject.map { $0 == .authorized }.asDriver(onErrorJustReturn: false).distinctUntilChanged()
        
        sessionService
            .sessionEvents(sessionIdentifier: sessionIdentifier)
            .subscribe(onNext: { [weak self] session in
                self?.updateWithSession(session)
            }, onError: { error in
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    private func updateWithSession(_ session: Session) {
        statusSubject.onNext(session.status)
        
        let age = Date().timeIntervalSince(session.startDate)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2
        if let formattedAge = formatter.string(from: age) {
            let title = String(format: Strings.startedAgo, formattedAge)
            titleSubject.accept(title)
        }
        
        if let eta = session.eta {
            let routeTime = eta.duration
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .short
            formatter.maximumUnitCount = 2
            
            if let formattedETA = formatter.string(from: routeTime) {
                etaSubject.accept(formattedETA)
            }
        } else {
            etaSubject.accept(nil)
        }
        
        _ = userService
            .getUser(session.userIdentifier)
            .subscribe(onSuccess: { [weak self] user in
                guard session.userIdentifier == user.identifier else { return }
                self?.userSubject.accept(user)
            }, onFailure: { error in
                print("Could not get user: \(error)")
            })
    }
}

extension SessionCellViewModel {
    func authorizeSession() {
        cloudService
            .authorize()
            .andThen(
                cloudService.authorizeSession(sessionIdentifier: sessionIdentifier))
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension SessionCellViewModel {
    struct Strings {
        static let etaUnavailable = "ETA unavailable"
        static let startedAgo = "Started %@ ago"
    }
}
