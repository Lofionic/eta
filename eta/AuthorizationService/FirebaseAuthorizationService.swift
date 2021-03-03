//
//  FirebaseAuthorizationService.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import FirebaseAuth
import RxCocoa
import RxSwift

final class FirebaseAuthorizationService: AuthorizationService {
    
    let stateDidChange: Observable<User?>
    let stateDidChangeSubject = PublishRelay<User?>()
    
    let stateDidChangeListenerHandle: AuthStateDidChangeListenerHandle
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    init() {
        stateDidChange = stateDidChangeSubject.asObservable()
        let stateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak stateDidChangeSubject] _, user in
            stateDidChangeSubject?.accept(user)
        }
        
        self.stateDidChangeListenerHandle = stateDidChangeListenerHandle
    }
    
    deinit {
        Auth.auth().removeStateDidChangeListener(stateDidChangeListenerHandle)
    }
    
    func createUser(withEmail email: Email, password: Password) -> Single<User> {
        return Single.create { single in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    single(.failure(error))
                } else if let result = result {
                    single(.success(result.user))
                }
            }
            return Disposables.create()
        }
    }
    
    func signIn(withEmail email: Email, password: Password) -> Single<User> {
        return Single.create { single in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    single(.failure(error))
                } else if let result = result {
                    single(.success(result.user))
                }
            }
            return Disposables.create()
        }
    }
    
    func signOut() -> Completable {
        return Completable.create { completable in
            do {
                try Auth.auth().signOut()
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
    }
}

extension FirebaseAuth.User: User {}
