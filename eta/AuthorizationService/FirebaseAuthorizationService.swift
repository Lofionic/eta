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
    
    let stateDidChange: Observable<String?>
    let stateDidChangeSubject = PublishRelay<FirebaseAuth.User?>()
    
    let stateDidChangeListenerHandle: AuthStateDidChangeListenerHandle
    
    var currentUser: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        stateDidChange = stateDidChangeSubject
            .map { $0?.uid }
            .asObservable()
        
        let stateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak stateDidChangeSubject] _, user in
            stateDidChangeSubject?.accept(user)
        }
        
        self.stateDidChangeListenerHandle = stateDidChangeListenerHandle
    }
    
    deinit {
        Auth.auth().removeStateDidChangeListener(stateDidChangeListenerHandle)
    }
    
    func createUser(withEmail email: Email, password: Password) -> Single<String> {
        return Single.create { single in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    single(.failure(error))
                } else if let result = result {
                    single(.success(result.user.uid))
                }
            }
            return Disposables.create()
        }
    }
    
    func signIn(withEmail email: Email, password: Password) -> Single<String> {
        return Single.create { single in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    single(.failure(error))
                } else if let result = result {
                    single(.success(result.user.uid))
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
    
    func getIDToken() -> Single<String> {
        return Single.create { single in
            Auth.auth().currentUser?.getIDToken { token, error in
                if let error = error {
                    single(.failure(error))
                } else {
                    if let token = token {
                        single(.success(token))
                    }
                }
            }
            return Disposables.create()
        }
        
    }
}

