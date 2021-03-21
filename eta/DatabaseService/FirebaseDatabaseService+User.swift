//
//  FirebaseDatabaseService+User.swift
//  eta
//
//  Created by Chris Rivers on 15/03/2021.
//

import FirebaseDatabase
import RxSwift

extension FirebaseDatabaseService {
    fileprivate func getUser(_ userIdentifier: UserIdentifier, completion: @escaping (Result<User, Error>) -> Void) {
        let reference = database.child("/\(Keys.users)/\(userIdentifier)")
        getData(query: reference, completion: completion)
    }
    
    fileprivate func subscribeToUser(
        userIdentifier: UserIdentifier,
        events: ObservedEvents,
        onEvent: @escaping (DataEvent<User>) -> Void,
        onError: @escaping (Error) -> Void) -> [DatabaseHandle]
    {
        let query = database.child(Keys.users).child(userIdentifier)
        return observeEvents(query: query, events: events, onEvent: onEvent, onError: onError)
    }
    
    fileprivate func unsubscribeToUsersWithHandles(_ handles: [DatabaseHandle]) {
        handles.forEach {
            database.child(Keys.users).removeObserver(withHandle: $0)
        }
    }
}

extension FirebaseDatabaseService: UserService {
    func getUser(_ userIdentifier: UserIdentifier) -> Single<User> {
        return Single.create { [weak self] single in
            self?.getUser(userIdentifier) { result in
                switch result {
                case .success(let user):
                single(.success(user))
                case .failure(let error):
                single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
    
    func userEvents(userIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<User>> {
        return Observable.create { [weak self] observable in
            let handles = self?.subscribeToUser(userIdentifier: userIdentifier,
                events: events,
                onEvent: { observable.onNext($0) },
                onError: { observable.onError($0) })
            return Disposables.create { [handles] in
                guard let handles = handles else { return }
                self?.unsubscribeToUsersWithHandles(handles)
            }
        }
    }
}
