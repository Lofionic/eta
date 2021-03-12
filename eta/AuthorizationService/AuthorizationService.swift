//
//  AuthorizationService.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import RxSwift

typealias Email = String
typealias Password = String

protocol AuthorizationService {
    func createUser(withEmail: Email, password: Password) -> Single<String>
    func signIn(withEmail: Email, password: Password) -> Single<String>
    func signOut() -> Completable
    
    var currentUser: String? { get }
    var stateDidChange: Observable<String?> { get }
}
