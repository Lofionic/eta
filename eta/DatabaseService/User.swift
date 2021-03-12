//
//  User.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

struct User: Codable {
    let identifier: UserIdentifier
    let email: Email?
    let username: Username?
}
