//
//  FirebaseDatabaseService.swift
//  eta
//
//  Created by Chris Rivers on 10/03/2021.
//

import FirebaseDatabase

import RxSwift

protocol SnapshotDecodable: Decodable {
    static func decode(_ snapshot: DataSnapshot) -> Self?
}

extension SnapshotDecodable {
    static func decode(_ snapshot: DataSnapshot) -> Self? {
        guard let dictionary = snapshot.value as? [String: AnyObject] else {
            return nil
        }
        do {
            let identifierDictionary = dictionary.merging(["identifier": snapshot.key as AnyObject]) { (current, _) in current }
            let json = try JSONSerialization.data(withJSONObject: identifierDictionary, options: [])
            return try JSONDecoder().decode(Self.self, from: json)
        } catch {
            return nil
        }
    }
}

final class FirebaseDatabaseService {
    
    struct Keys {
        static let sessions = "sessions"
        struct Session {
            static let userIdentifier = "userIdentifier"
        }
    }
    
    let database: DatabaseReference
    
    private var sessionHandles: [DatabaseHandle]!
    
    init(database: DatabaseReference = Database.database().reference()) {
        self.database = database
    }
    
    private func subscribeToQueryEvents<T: SnapshotDecodable>(query: DatabaseQuery, onEvent: @escaping (DatabaseEvent<T>) -> Void) -> [DatabaseHandle] {
        let added = query.observe(.childAdded) { snapshot in
            if let element = T.decode(snapshot) {
                onEvent(.added(element))
            }
        }
        
        let changed = query.observe(.childChanged) { snapshot in
            if let element = T.decode(snapshot) {
                onEvent(.changed(element))
            }
        }
        
        let removed = query.observe(.childRemoved) { snapshot in
            if let element = T.decode(snapshot) {
                onEvent(.removed(element))
            }
        }
        
        let moved = query.observe(.childMoved) { snapshot in
            if let element = T.decode(snapshot) {
                onEvent(.moved(element))
            }
        }
        
        return [added, changed, removed, moved]
    }
    
    func subscribeToSessions(
        userIdentifier: UserIdentifier, onEvent: @escaping (DatabaseEvent<Session>) -> Void)
    {
        let query = database.child(Keys.sessions).queryOrdered(byChild: Keys.Session.userIdentifier).queryEqual(toValue: userIdentifier)
        sessionHandles = subscribeToQueryEvents(query: query, onEvent: onEvent)
    }
    
    func unsubscribeToSessions() {
        sessionHandles.forEach {
            database.child(Keys.sessions).removeObserver(withHandle: $0)
        }
    }
}

extension FirebaseDatabaseService: DatabaseService {
    
    func sessions(userIdentifier: UserIdentifier) -> Observable<DatabaseEvent<Session>> {
        return Observable.create { [weak self] observable in
            self?.subscribeToSessions(userIdentifier: userIdentifier) {
                observable.onNext($0)
            }
            return Disposables.create()
        }.do(onDispose: { [weak self] in
            self?.unsubscribeToSessions()
        })
    }
}

extension Session: SnapshotDecodable {}
