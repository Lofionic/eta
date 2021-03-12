//
//  Created by Lofionic ©2021
//

import RxSwift

private struct PostResponse: Decodable {
    let name: String
}

final class LocalCloudService: HTTPService {
    
    init() {
        super.init(scheme: .http, domain: "127.0.0.1", port: 8080)
    }
    
    func startSession(userIdentifier: UserIdentifier, friendIdentifier: UserIdentifier, expiresAfter: Double) -> Completable {
        let request = StartSession(userIdentifier: userIdentifier, friendIdentifier: friendIdentifier, expiresAfter: expiresAfter)
        return Completable.create { [weak self] completable in
            guard let self = self else {
                return Disposables.create()
            }
            do {
                let _: PostResponse = try self.makeRequest(request)
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .observe(on: MainScheduler.instance)
    }
    
    func postLocationUpdate(userIdentifier: UserIdentifier, sessionIdentifier: SessionIdentifier, locationUpdate: LocationUpdate) -> Completable {
        return Completable.empty()
    }
}

private struct StartSession: HTTPRequest {

    struct PostData: Encodable {
        let userIdentifier: UserIdentifier
        let friendIdentifier: UserIdentifier
        let expiresAfter: Double
    }
    
    var path = "/session/v1/create"
    var method = HTTPRequestMethod.post
    var queryItems: [String : String] = [:]
    var body: Data? {
        let jsonEncoder = JSONEncoder()
        let post = PostData(userIdentifier: userIdentifier, friendIdentifier: friendIdentifier, expiresAfter: expiresAfter)
        return try? jsonEncoder.encode(post)
    }
    func setHeaders(urlRequest: inout URLRequest) {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    let userIdentifier: UserIdentifier
    let friendIdentifier: UserIdentifier
    let expiresAfter: Double
}
