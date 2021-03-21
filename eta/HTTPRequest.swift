//
//  Created by Chris Rivers
//

import Foundation

enum HTTPRequestMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
}

protocol HTTPRequest {
	var path: String { get }

	var method: HTTPRequestMethod { get }
	var queryItems: [String: String] { get }
	var body: Data? { get }
    
    func setHeaders(urlRequest: inout URLRequest)
}

extension HTTPRequest {
    func setHeaders(urlRequest: inout URLRequest) {}
    
    var method: HTTPRequestMethod { .get }
    var queryItems: [String: String] { [:] }
    var body: Data? { nil }
}
