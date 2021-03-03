//
//  AuthorizationService.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import RxSwift

protocol User {
    var uid: String { get }
}

typealias Email = String
typealias Password = String

protocol AuthorizationService {
    func createUser(withEmail: Email, password: Password) -> Single<User>
    func signIn(withEmail: Email, password: Password) -> Single<User>
    func signOut() -> Completable
    
    var currentUser: User? { get }
    var stateDidChange: Observable<User?> { get }
}
