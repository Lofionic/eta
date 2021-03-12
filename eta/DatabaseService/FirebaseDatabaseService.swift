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

enum FirebaseDatabaseServiceError: Error {
    case decodingError
    case unknown
}

final class FirebaseDatabaseService {
    struct Keys {
        static let sessions = "sessions"
        struct Session {
            static let userIdentifier = "userIdentifier"
        }
        static let users = "users"
        struct User {
            static let email = "email"
        }
    }
    
    private let database: DatabaseReference
    private var sessionHandles: [DatabaseHandle]!
    
    init(database: DatabaseReference = Database.database().reference()) {
        self.database = database
    }
}

// MARK: - Generic utility functions
extension FirebaseDatabaseService {
    private func getData<T: SnapshotDecodable>(query: DatabaseQuery, completion: @escaping (Result<T, Error>) -> Void) {
        query.getData(completion: { (error, snapshot) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let result = T.decode(snapshot) {
                    completion(.success(result))
                } else {
                    completion(.failure(FirebaseDatabaseServiceError.decodingError))
                }
            }
        })
    }
    
    private func subscribeToQueryEvents<T: SnapshotDecodable>(query: DatabaseQuery, onEvent: @escaping (DataEvent<T>) -> Void) -> [DatabaseHandle] {
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
}

//MARK: - Sessions
extension FirebaseDatabaseService {
    private func createSession(userIdentifier: UserIdentifier, completion: @escaping (Result<SessionIdentifier?, Error>) -> Void) {
        let reference = database.child("/\(Keys.sessions)").childByAutoId()
        
        let date = Date().timeIntervalSinceReferenceDate
        let dictionary: [String: AnyObject] = [
            "userIdentifier": userIdentifier as AnyObject,
            "status": 0 as AnyObject,
            "startDate": date as AnyObject,
            "lastUpdated": 0 as AnyObject,
            "expiresAfter": 60 as AnyObject,
        ]
        
        reference.setValue(dictionary) { error, reference in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(reference.key))
            }
        }
    }
    
    private func subscribeToSessions(
        userIdentifier: UserIdentifier, onEvent: @escaping (DataEvent<Session>) -> Void)
    {
        let query = database.child(Keys.sessions).queryOrdered(byChild: Keys.Session.userIdentifier).queryEqual(toValue: userIdentifier)
        sessionHandles = subscribeToQueryEvents(query: query, onEvent: onEvent)
    }
    
    private func unsubscribeToSessions() {
        sessionHandles.forEach {
            database.child(Keys.sessions).removeObserver(withHandle: $0)
        }
    }
}

//MARK: - Users
extension FirebaseDatabaseService {
    private func registerUser(_ userIdentifier: String, email: String, completion: @escaping () -> Void) {
        let reference = database.child("/\(Keys.users)/\(userIdentifier)")
        let dictionary: [String: AnyObject] = [Keys.User.email: email.lowercased() as AnyObject]
        reference.setValue(dictionary)
        completion()
    }
    
    private func getUser(_ userIdentifier: UserIdentifier, completion: @escaping (Result<User, Error>) -> Void) {
        let reference = database.child("/\(Keys.users)/\(userIdentifier)")
        getData(query: reference, completion: completion)
    }
}

extension FirebaseDatabaseService: SessionService {
    func sessions(userIdentifier: UserIdentifier) -> Observable<DataEvent<Session>> {
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
}

extension FirebaseDatabaseService: CloudService {
    func registerUser(_ userIdentifier: String, email: String) -> Completable {
        return Completable.create { [weak self] completable in
            self?.registerUser(userIdentifier, email: email) {
                completable(.completed)
            }
            return Disposables.create()
        }
    }
    
    func createSession(userIdentifier: UserIdentifier) -> Single<SessionIdentifier?> {
        return Single.create { [weak self] single in
            self?.createSession(userIdentifier: userIdentifier) { result in
                switch result {
                case .success(let key):
                    single(.success(key))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
    
}

extension Session: SnapshotDecodable {}
extension User: SnapshotDecodable {}
