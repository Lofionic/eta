//
//  Created by Lofionic ©2021
//

import RxSwift

private struct Response: Decodable {}

private struct PostResponse: Decodable {
    let name: String
}

extension SessionConfiguration {
    static let `default` = SessionConfiguration(expiresAfter: 3600, privateMode: true)
}

final class RemoteCloudService: HTTPService, CloudService {
    
    var authenticationService: AuthorizationService?
    
    func authorize() -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self, let authenticationService = self.authenticationService else {
                return Disposables.create()
            }
            _ = authenticationService
                .getIDToken()
                .subscribe(onSuccess: { authorizationToken in
                    self.authorizationToken = authorizationToken
                    completable(.completed)
                }, onFailure: { error in
                    completable(.error(error))
                })
                return Disposables.create()
        }
    }
    
    func registerUser(_ userIdentifier: UserIdentifier, email: Email) -> Single<UserIdentifier?> {
        fatalError()
    }
    
    private func completableForRequest(_ request: HTTPRequest) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                return Disposables.create()
            }
            do {
                let _: Response = try self.doRequest(request)
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .observe(on: MainScheduler.instance)
    }
    
    func createSession(userIdentifier: UserIdentifier, configuration: SessionConfiguration) -> Single<SessionIdentifier> {
        let request = CreateSession(userIdentifier: userIdentifier, configuration: configuration)
        return Single.create { [weak self] single in
            guard let self = self else {
                return Disposables.create()
            }
            do {
                let response: PostResponse = try self.doRequest(request)
                single(.success(response.name))
            } catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .observe(on: MainScheduler.instance)
    }
    
    func removeSession(sessionIdentifier: SessionIdentifier) -> Completable {
        let request = RemoveSession(sessionIdentifier: sessionIdentifier)
        return completableForRequest(request)
    }
    
    func joinSession(sessionIdentifier: SessionIdentifier) -> Completable {
        let request = JoinSession(sessionIdentifier: sessionIdentifier)
        return completableForRequest(request)
    }
    
    func authorizeSession(sessionIdentifier: SessionIdentifier) -> Completable {
        let request = AuthorizeSession(sessionIdentifier: sessionIdentifier)
        return completableForRequest(request)
    }
    
    func postLocation(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier, location: Location) -> Completable {
        let request = PostLocation(sessionIdentifier: sessionIdentifier, location: location)
        return completableForRequest(request)
    }
}

private struct CreateSession: HTTPRequest {
    var path: String { "/session/v1/create/\(userIdentifier)" }
    var body: Data? { try? jsonEncoder.encode(configuration) }
    func setHeaders(urlRequest: inout URLRequest) {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    var method: HTTPRequestMethod = .post
    
    let userIdentifier: UserIdentifier
    let configuration: SessionConfiguration
    
    private let jsonEncoder = JSONEncoder()
}

private struct RemoveSession: HTTPRequest {
    var path: String { "/session/v1/remove/\(sessionIdentifier)" }
    let sessionIdentifier: SessionIdentifier
}

private struct JoinSession: HTTPRequest {
    var path: String { "/session/v1/join/\(sessionIdentifier)/" }
    let sessionIdentifier: SessionIdentifier
}

private struct AuthorizeSession: HTTPRequest {
    var path: String { "/session/v1/authorize/\(sessionIdentifier)/" }
    let sessionIdentifier: SessionIdentifier
}

private struct PostLocation: HTTPRequest {
    var path: String { "/session/v1/location/\(sessionIdentifier)" }
    var body: Data? { try? jsonEncoder.encode(location) }
    func setHeaders(urlRequest: inout URLRequest) {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    var method: HTTPRequestMethod = .post
    
    let sessionIdentifier: SessionIdentifier
    let location: Location
    
    private let jsonEncoder = JSONEncoder()
}
