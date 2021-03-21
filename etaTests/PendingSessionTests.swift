//
//  PendingSessionTests.swift
//  etaTests
//
//  Created by Chris Rivers on 16/03/2021.
//

import XCTest

import RxSwift
import RxTest

@testable import eta

final class PendingSessionTests: XCTestCase {
	
	private let disposeBag = DisposeBag()
	private let testScheduler = TestScheduler(initialClock: 0)
	
	func testPushingSessionCreatesEvent() {
		let pending = PendingSessionController()
		let observer = testScheduler.createObserver(SessionIdentifier.self)
		
		pending.rx.pendingSessions().subscribe(observer).disposed(by: disposeBag)
		
		let sessionIdentifier = UUID().uuidString
		testScheduler.scheduleAt(1) { pending.addPendingSession(sessionIdentifier) }
		testScheduler.start()
		
		let expectedEvents: [Recorded<Event<SessionIdentifier>>] = [
			.next(1, sessionIdentifier)
		]
		
		XCTAssertEqual(expectedEvents, observer.events)
	}
	
	func testPendingSessionIsPushedWhenFirstObserved() {
		let pending = PendingSessionController()
		let sessionIdentifier = UUID().uuidString
		pending.addPendingSession(sessionIdentifier)
		
		let observer = testScheduler.createObserver(SessionIdentifier.self)
		pending.rx.pendingSessions().subscribe(observer).disposed(by: disposeBag)

		let expectedEvents: [Recorded<Event<SessionIdentifier>>] = [
			.next(0, sessionIdentifier)
		]
		XCTAssertEqual(expectedEvents, observer.events)
	}
	
	func testPendingSessionIsPushedExactlyOnceWhenObservedMultipleTimes() {
		let pending = PendingSessionController()
		let sessionIdentifier = UUID().uuidString
		pending.addPendingSession(sessionIdentifier)
		
		let observer = testScheduler.createObserver(SessionIdentifier.self)
		pending.rx.pendingSessions().subscribe(observer).disposed(by: disposeBag)
		
		let secondObserver = testScheduler.createObserver(SessionIdentifier.self)
		pending.rx.pendingSessions().subscribe(secondObserver).disposed(by: disposeBag)
		XCTAssertEqual(secondObserver.events, [])
	}
	
	func testSessionsArePusheAfterPendingSessionIsPushed() {
		let pending = PendingSessionController()
		let sessionIdentifier = UUID().uuidString
		pending.addPendingSession(sessionIdentifier)
		
		let observer = testScheduler.createObserver(SessionIdentifier.self)
		pending.rx.pendingSessions().subscribe(observer).disposed(by: disposeBag)

		let followUpSessionIdentifier = UUID().uuidString
		testScheduler.scheduleAt(1) { pending.addPendingSession(followUpSessionIdentifier) }
		testScheduler.start()
		
		let expectedEvents: [Recorded<Event<SessionIdentifier>>] = [
			.next(0, sessionIdentifier),
			.next(1, followUpSessionIdentifier)
		]
		XCTAssertEqual(expectedEvents, observer.events)
	}
}
