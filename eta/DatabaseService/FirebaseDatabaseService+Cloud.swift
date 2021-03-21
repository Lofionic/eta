//
//  FirebaseDatabaseService+Cloud.swift
//  eta
//
//  Created by Chris Rivers on 15/03/2021.
//

import FirebaseDatabase
import RxSwift

private extension FirebaseDatabaseService {
    func registerUser(_ userIdentifier: String, email: String, completion: @escaping (Result<UserIdentifier?, Error>) -> Void) {
        let reference = database.child("/\(Keys.users)/\(userIdentifier)")
        let dictionary: [String: AnyObject] = [Keys.User.email: email.lowercased() as AnyObject]
        
        reference.setValue(dictionary) { error, reference in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(reference.key))
            }
        }
    }

    func createSession(userIdentifier: UserIdentifier, completion: @escaping (Result<SessionIdentifier?, FirebaseDatabaseServiceError>) -> Void) {
        let date = Date().timeIntervalSinceReferenceDate
        let dictionary: [String: AnyObject] = [
            "userIdentifier": userIdentifier as AnyObject,
            "status": 0 as AnyObject,
            "startDate": date as AnyObject,
            "lastUpdated": 0 as AnyObject,
            "expiresAfter": 60 as AnyObject,
        ]
        
       database
            .child(Keys.sessions)
            .queryOrdered(byChild: Keys.Session.userIdentifier)
            .queryEqual(toValue: userIdentifier)
            .observeSingleEvent(of: .value) { [weak database] snapshot in
                guard snapshot.childrenCount == 0 else {
                    return completion(.failure(.sessionExistsForUser))
                }
                guard let database = database else { return }
                database
                    .child("/\(Keys.sessions)")
                    .childByAutoId()
                    .setValue(dictionary) { error, reference in
                        if let error = error {
                            completion(.failure(.error(underlyingError: error)))
                        } else {
                            completion(.success(reference.key))
                        }
                }
            }
    }
    
    func joinSession(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier, completion: @escaping (Result<Void, FirebaseDatabaseServiceError>) -> Void) {
        let verify = database
            .child(Keys.sessions)
            .queryOrdered(byChild: Keys.Session.subscriberIdentifier)
            .queryEqual(toValue: userIdentifier)
        print("\(#function) verifying: \(verify)")
        
        verify.getData { [weak database] error, snapshot in
            guard let database = database else { return }
            if let error = error {
                completion(.failure(.errorValidating(underlyingError: error)))
            } else if snapshot.exists() {
                completion(.failure(.sessionFull))
            } else {
                let reference = database.child("/\(Keys.sessions)/\(sessionIdentifier)").child(Keys.Session.subscriberIdentifier)
                print("\(#function) SetValue \(userIdentifier) at \(reference)")
                reference.setValue(userIdentifier)
                { error, reference in
                    if let error = error {
                        completion(.failure(.error(underlyingError: error)))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func removeSession(sessionIdentifier: SessionIdentifier, completion: @escaping (Result<Void, Error>) -> Void) {
        let reference = database.child("/\(Keys.sessions)/\(sessionIdentifier)")
        reference.setValue(nil) { error, reference in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func setSessionStatus(
        sessionIdentifier: SessionIdentifier,
        status: SessionStatus,
        completion: @escaping (Result<Void, Error>) -> Void)
    {
        let reference = database.child("/\(Keys.sessions)/\(sessionIdentifier)/\(Keys.Session.status)")
        reference.setValue(status.rawValue) { error, reference in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

//extension FirebaseDatabaseService: CloudService {
//    func registerUser(_ userIdentifier: String, email: String) -> Single<UserIdentifier?> {
//        return Single.create { [weak self] single in
//            self?.registerUser(userIdentifier, email: email) { result in
//                switch result {
//                case .success(let userIdentifier):
//                    single(.success(userIdentifier))
//                case .failure(let error):
//                    single(.failure(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//    
//    func createSession(userIdentifier: UserIdentifier) -> Single<SessionIdentifier?> {
//        return Single.create { [weak self] single in
//            self?.createSession(userIdentifier: userIdentifier) { result in
//                switch result {
//                case .success(let key):
//                    single(.success(key))
//                case .failure(let error):
//                    single(.failure(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//    
//    func removeSession(sessionIdentifier: SessionIdentifier) -> Completable {
//        return Completable.create { [weak self] completable in
//            self?.removeSession(sessionIdentifier: sessionIdentifier) { result in
//                switch result {
//                case .success():
//                    completable(.completed)
//                case .failure(let error):
//                    completable(.error(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//    
//    func joinSession(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier) -> Completable {
//        return Completable.create { [weak self] completable in
//            self?.joinSession(userIdentifier: userIdentifier, sessionIdentifier: sessionIdentifier) { result in
//                switch result {
//                case .success():
//                    completable(.completed)
//                case .failure(let error):
//                    completable(.error(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//    
//    func authorizeSession(sessionIdentifier: SessionIdentifier) -> Completable {
//        return Completable.create { [weak self] completable in
//            self?.setSessionStatus(sessionIdentifier: sessionIdentifier, status: .authorized) { result in
//                switch result {
//                case .success():
//                    completable(.completed)
//                case .failure(let error):
//                    completable(.error(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//}
