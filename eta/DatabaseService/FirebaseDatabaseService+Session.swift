//
//  FirebaseDatabaseService+Sessions.swift
//  eta
//
//  Created by Chris Rivers on 15/03/2021.
//

import FirebaseDatabase
import RxSwift

private extension FirebaseDatabaseService {
    
    private static let jsonDecoder: JSONDecoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZ"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return decoder
    }()
    
    func subscribeToSessions(
        subscriberIdentifier: UserIdentifier,
        events: ObservedEvents,
        onEvent: @escaping (DataEvent<Session>) -> Void,
        onError: @escaping (Error) -> Void) -> [DatabaseHandle]
    {
        let query = database
            .child(Keys.sessions)
            .queryOrdered(byChild: Keys.Session.subscriberIdentifier)
            .queryEqual(toValue: subscriberIdentifier)
        
        return observeEvents(query: query, events: events, jsonDecoder: Self.jsonDecoder, onEvent: onEvent, onError: onError)
    }
    
    func subscribeToSessions(
        userIdentifier: UserIdentifier,
        events: ObservedEvents,
        onEvent: @escaping (DataEvent<Session>) -> Void,
        onError: @escaping (Error) -> Void) -> [DatabaseHandle]
    {
        let query = database
            .child(Keys.sessions)
            .queryOrdered(byChild: Keys.Session.userIdentifier)
            .queryEqual(toValue: userIdentifier)
        
        return observeEvents(query: query, events: events, jsonDecoder: Self.jsonDecoder, onEvent: onEvent, onError: onError)
    }
    
    func subscribeToSession(
        sessionIdentifier: SessionIdentifier,
        events: ObservedEvents,
        onEvent: @escaping (DataEvent<Session>) -> Void,
        onError: @escaping (Error) -> Void) -> [DatabaseHandle]
    {
        let query = database.child(Keys.sessions).child(sessionIdentifier)
        return observeEvents(query: query, events: events, jsonDecoder: Self.jsonDecoder, onEvent: onEvent, onError: onError)
    }
    
    func unsubscribeToSessionsWithHandles(_ handles: [DatabaseHandle]) {
        handles.forEach {
            database.child(Keys.sessions).removeObserver(withHandle: $0)
        }
    }
}

extension FirebaseDatabaseService: SessionService {
    
    func sessionEvents(userIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<Session>> {
        return Observable.create { [weak self] observable in
            let handles = self?.subscribeToSessions(
                userIdentifier: userIdentifier,
                events: events,
                onEvent: { observable.onNext($0) },
                onError: { observable.onError($0) })
            return Disposables.create { [handles] in
                guard let handles = handles else { return }
                self?.unsubscribeToSessionsWithHandles(handles)
            }
        }
    }
    
    func sessionEvents(subscriberIdentifier: UserIdentifier, events: ObservedEvents) -> Observable<DataEvent<Session>> {
        return Observable.create { [weak self] observable in
            let handles = self?.subscribeToSessions(
                subscriberIdentifier: subscriberIdentifier,
                events: events,
                onEvent: { observable.onNext($0) },
                onError: { observable.onError($0) })
            return Disposables.create { [handles] in
                guard let handles = handles else { return }
                self?.unsubscribeToSessionsWithHandles(handles)
            }
        }
    }
    
    func sessionEvents(sessionIdentifier: SessionIdentifier) -> Observable<Session> {
        return Observable.create { [weak self] observable in
            let handles = self?.subscribeToSession(
                sessionIdentifier: sessionIdentifier,
                events: [.value],
                onEvent: {
                    if case .value(let session) = $0 {
                        observable.onNext(session)
                    }
                },
                onError: {
                    observable.onError($0)
                })
            return Disposables.create { [handles] in
                guard let handles = handles else { return }
                self?.unsubscribeToSessionsWithHandles(handles)
            }
        }
    }
}
