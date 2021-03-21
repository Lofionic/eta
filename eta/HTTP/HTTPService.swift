//
//  Created by Chris Rivers
//

import Foundation

enum HTTPServiceScheme: String {
    case http
    case https
}

enum HTTPServiceError: Swift.Error {
    case cannotFormURL
    case invalidResponse
    case invalidStatusCode(statusCode: Int)
    case error(underlyingError: Error)
    case unknown
}

class HTTPService {
    
    let scheme: HTTPServiceScheme
    let domain: String
    let port: Int?
    
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()
    
    var queryItems: [String: String] { [:] }
    var authorizationToken: String?
    
    init(scheme: HTTPServiceScheme, domain: String, port: Int? = nil) {
        self.scheme = scheme
        self.domain = domain
        self.port = port
    }
    
    func doRequest<T: Decodable>(_ request: HTTPRequest) throws -> T {
        guard let url = getURLForRequest(request) else {
            throw HTTPServiceError.cannotFormURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        request.setHeaders(urlRequest: &urlRequest)
        
        if let authorizationToken = authorizationToken {
            urlRequest.setValue("Bearer \(authorizationToken)", forHTTPHeaderField: "Authorization")
        }
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: urlSessionConfiguration)
        
        let (data, response, error) = session.synchronousDataTask(with: urlRequest)
        
        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw HTTPServiceError.invalidResponse
        }
        
        guard httpURLResponse.statusCode == 200 else {
            throw HTTPServiceError.invalidStatusCode(statusCode: httpURLResponse.statusCode)
        }
        
        if let error = error {
            throw error
        } else if let data = data {
            do {
                let decoded = try jsonDecoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw HTTPServiceError.error(underlyingError: error)
            }
        }
        
        throw HTTPServiceError.unknown
    }
    
    func getURLForRequest(_ request: HTTPRequest) -> URL? {
        let queryItems = self.queryItems.urlQueryItems
        let requestQueryItems = request.queryItems.urlQueryItems
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme.rawValue
        urlComponents.host = domain
        urlComponents.port = port
        urlComponents.path = request.path
        urlComponents.queryItems = queryItems + requestQueryItems
        
        return urlComponents.url
    }
}

private extension Dictionary where Key == String, Value == String {
    var urlQueryItems: [URLQueryItem] {
        map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}

private extension URLSession {
    func synchronousDataTask(with urlRequest: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: urlRequest) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
