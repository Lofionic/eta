//
//  SessionCellViewModel.swift
//  eta
//
//  Created by Chris Rivers on 18/03/2021.
//

import Foundation

import RxCocoa
import RxSwift

final class SessionCellViewModel: ViewModel {
    
    let title: Driver<String>
    let eta: Driver<String?>
    let isAuthorized: Driver<Bool>
    
    let sessionIdentifier: SessionIdentifier
    let sessionService: SessionService
    let userService: UserService
    let cloudService: CloudService
    
    private let statusSubject = PublishSubject<SessionStatus>()
    private let titleSubject = PublishSubject<String>()
    private let etaSubject = PublishSubject<String?>()
    
    private let authorize = PublishSubject<Void>()
    
    private let disposeBag = DisposeBag()
    
    init(sessionIdentifier: SessionIdentifier, sessionService: SessionService, userService: UserService, cloudService: CloudService) {
        self.sessionIdentifier = sessionIdentifier
        self.sessionService = sessionService
        self.userService = userService
        self.cloudService = cloudService
        
        title = titleSubject.asDriver(onErrorDriveWith: .never()).distinctUntilChanged()
        eta = etaSubject.asDriver(onErrorDriveWith: .never()).distinctUntilChanged()
        isAuthorized = statusSubject.map { $0 == .authorized }.asDriver(onErrorJustReturn: false).distinctUntilChanged()
        
        sessionService
            .sessionEvents(sessionIdentifier: sessionIdentifier, events: [.value])
            .subscribe(onNext: { [weak self] event in
                if case .value(let session) = event {
                    self?.updateWithSession(session)
                }
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
            titleSubject.onNext(title)
        }
        
        if let eta = session.eta {
            let routeTime = TimeInterval(eta.route.time)
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .short
            formatter.maximumUnitCount = 2
            
            if let formattedETA = formatter.string(from: routeTime) {
                etaSubject.onNext(formattedETA)
            }
        } else {
            etaSubject.onNext(nil)
        }
        
        _ = userService
            .getUser(session.userIdentifier)
            .subscribe(onSuccess: { user in
                print("User is: \(String(describing: user.email))")
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
