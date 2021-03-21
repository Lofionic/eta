//
//  AuthorizationService.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import RxSwift

typealias UserIdentifier = String
typealias Email = String
typealias Password = String

protocol AuthorizationService {
    func createUser(withEmail: Email, password: Password) -> Single<UserIdentifier>
    func signIn(withEmail: Email, password: Password) -> Single<UserIdentifier>
    func signOut() -> Completable
    func getIDToken() -> Single<String>
    
    var currentUser: UserIdentifier? { get }
    var stateDidChange: Observable<UserIdentifier?> { get }
}
