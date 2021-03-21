//
//  PendingSession.swift
//  eta
//
//  Created by Chris Rivers on 15/03/2021.
//

import RxCocoa
import RxSwift

final class PendingSessionController {
    
    static let shared = PendingSessionController()
    
	fileprivate let newSessionIdentifier: Observable<SessionIdentifier>
	
	private let newSessionIdentifierRelay = PublishRelay<SessionIdentifier>()
	private var sessionIdentifier: SessionIdentifier?
	
	init() {
		newSessionIdentifier = newSessionIdentifierRelay.asObservable()
	}
	
    public func addPendingSession(_ sessionIdentifier: SessionIdentifier) {
		self.sessionIdentifier = sessionIdentifier
		newSessionIdentifierRelay.accept(sessionIdentifier)
    }
	
	public func popPendingSession() -> SessionIdentifier? {
		defer { sessionIdentifier = nil }
		return sessionIdentifier
	}
}

extension PendingSessionController: ReactiveCompatible {}

extension Reactive where Base == PendingSessionController {
	func pendingSessions() -> Observable<SessionIdentifier> {
		return Observable.create { observable in
			if let session = base.popPendingSession() {
				observable.onNext(session)
			}
			return base.newSessionIdentifier.subscribe(observable)
		}
	}
}

/*


func sessionEvents(friendIdentifier: UserIdentifier) -> Observable<DataEvent<Session>> {
	return Observable.create { [weak self] observable in
		let handles = self?.subscribeToSessions(friendIdentifier: friendIdentifier) {
			observable.onNext($0)
		}
		return Disposables.create { [handles] in
			guard let handles = handles else { return }
			self?.unsubscribeToSessionsWithHandles(handles)
		}
	}
}
*/
