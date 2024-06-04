//
//  LocationController.swift
//  eta
//
//  Created by Chris Rivers on 17/03/2021.
//

import CoreLocation

import RxSwift

final class LocationController: NSObject {
    
    private let userIdentifier: UserIdentifier
    private let sessionService: SessionService
    private let cloudService: CloudService
    private let authorizationService: AuthorizationService
    private let locationManager: CLLocationManager
    
    private var hostingSessions = Set<Session>()
    private var subscribedSessions = Set<Session>()
    
    private let locationSubject = PublishSubject<CLLocation>()
    
    private let disposeBag = DisposeBag()
    
    init(
        userIdentifier: UserIdentifier,
        sessionService: SessionService,
        cloudService: CloudService,
        authorizationService: AuthorizationService,
        locationManager: CLLocationManager = CLLocationManager())
    {
        self.userIdentifier = userIdentifier
        self.sessionService = sessionService
        self.cloudService = cloudService
        self.authorizationService = authorizationService
        self.locationManager = locationManager
        
        super.init()
        
        locationManager.delegate = self
        setup()
    }
    
    private func setup() {
        sessionService
            .sessionEvents(userIdentifier: userIdentifier, events: [.add, .remove])
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .added(let value):
                    self.hostingSessions.insert(value)
                case .removed(let value):
                    self.hostingSessions.remove(value)
                default:
                    break
                }
                self.checkPermissions()
            })
            .disposed(by: disposeBag)
        
        sessionService
            .sessionEvents(subscriberIdentifier: userIdentifier, events: [.add, .remove, .change])
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .added(let value):
                    self.subscribedSessions.insert(value)
                case .removed(let value):
                    self.subscribedSessions.remove(value)
                case .changed(let value):
                    self.subscribedSessions.remove(value)
                    self.subscribedSessions.insert(value)
                default:
                    break
                }
                self.checkPermissions()
            })
            .disposed(by: disposeBag)
        
        locationSubject
            .throttle(.seconds(10), latest: true, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] location in
                self?.dispatchLocation(location)
            })
            .disposed(by: disposeBag)
    }
    
    private func checkPermissions() {
        if hostingSessions.union(subscribedSessions.filter( { $0.status == .authorized })).isEmpty {
            print("Stopping updating location")
            locationManager.stopUpdatingLocation()
        } else {
            print("Starting updating location")
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    private func dispatchLocation(_ clLocation: CLLocation) {
        let location = Location(coordinate: Coordinate(clLocation), date: clLocation.timestamp)
        print("\(Date()): Dispatching location: \(location)")
        let completables =
            [cloudService.authorize()] +
            hostingSessions.map { dispatchLocation(location, sessionIdentifier: $0.identifier) } +
            subscribedSessions.filter { $0.status == .authorized }.map { dispatchLocation(location, sessionIdentifier: $0.identifier) }
        
        Completable
            .concat(completables)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func dispatchLocation(_ location: Location, sessionIdentifier: SessionIdentifier) -> Completable {
        cloudService.postLocation(
            userIdentifier: userIdentifier,
            sessionIdentifier: sessionIdentifier,
            location: location)
    }
}

extension LocationController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let clLocation = locations.last else { return }
        locationSubject.onNext(clLocation)
    }
}

extension Coordinate {
    init(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

extension Session: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
