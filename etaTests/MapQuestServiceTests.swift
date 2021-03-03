//
//  MapQuestServiceTests.swift
//  etaTests
//
//  Created by Chris Rivers on 03/03/2021.
//

import XCTest

@testable import eta

class DirectionServiceTests: XCTestCase {
	
	func testDirectionRequestQueryContainsKey() {
		
		let fromCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let toCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let request = MapQuestDirectionsRequest(from: fromCoordinate, to: toCoordinate)
		
		let key = UUID().uuidString
		let service = makeService(key: key)
		
		guard
			let url = service.getURLForRequest(request),
			let query = url.query else
		{
			XCTFail()
			return
		}
		
		XCTAssertTrue(query.contains("key=\(key)"))
	}
	
	func testDirectionRequestQueryContainsFromParameter() {
		
		let fromCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let toCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let request = MapQuestDirectionsRequest(from: fromCoordinate, to: toCoordinate)
		
		let service = makeService()
		
		guard
			let url = service.getURLForRequest(request),
			let query = url.query else
		{
			XCTFail()
			return
		}
		
		XCTAssertTrue(query.contains("from=0.0,0.0"))
	}
	
	func testDirectionRequestQueryContainsToParameter() {
		
		let fromCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let toCoordinate = MapQuestCoordinate(latitude: 0, longitude: 0)
		let request = MapQuestDirectionsRequest(from: fromCoordinate, to: toCoordinate)
		
		let service = makeService()
		
		guard
			let url = service.getURLForRequest(request),
			let query = url.query else
		{
			XCTFail()
			return
		}
		
		XCTAssertTrue(query.contains("to=0.0,0.0"))
	}
	
	private func makeService(key: String = UUID().uuidString) -> HTTPService {
		let domain = "www.test.com"
		return HTTPService(scheme: .http, domain: domain, key: key)
	}
}
