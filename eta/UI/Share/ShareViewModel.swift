//
//  Lofionic ©2021
//

import FirebaseAuth
import RxCocoa
import RxSwift

enum SessionDurations: Int, CaseIterable {
	case fifteenMinutes
	case thirtyMinutes
	case oneHour
	case twoHours
	case fiveHours
	
	var title: String {
		switch self {
		case .fifteenMinutes: return "Fifteen minutes"
		case .thirtyMinutes: return "Thirty minutes"
		case .oneHour: return "One hour"
		case .twoHours: return "Two hours"
		case .fiveHours: return "Five hours"
		}
	}
	
	var timeInterval: TimeInterval {
		switch self {
		case .fifteenMinutes: return 60 * 15
		case .thirtyMinutes: return 60 * 30
		case .oneHour: return 60 * 60
		case .twoHours: return 60 * 120
		case .fiveHours: return 60 * 300
		}
	}
}

final class ShareViewModel: ViewModel {
    
    let presentationState: Driver<ShareViewPresentationState>
    let isWorking: Driver<Bool>
    let link: Driver<String?>
    let share: Driver<Any>
    
    let durationOptions = Observable.just(SessionDurations.allCases.map{ $0.title })
    let durationRelay = BehaviorRelay(value: (row: Int(SessionDurations.allCases.count / 2), component: 0))
    let privateRelay = BehaviorRelay(value: true)
    
    private let presentationStateRelay = BehaviorRelay(value: ShareViewPresentationState.minimized)
    private let linkRelay = BehaviorRelay<String?>(value: nil)
    private let sessionRelay = BehaviorRelay<Session?>(value: nil)
    private let isWorkingRelay = BehaviorRelay(value: false)
    private let shareRelay = PublishRelay<Any>()
    
    let authorizationService: AuthorizationService
    let cloudService: CloudService
    let sessionService: SessionService
    let theme: Theme
    
    let strings = Strings()
    let disposeBag = DisposeBag()
        
    var presentHandler: () -> Void = {}
    var sessionAuthorizedHandler: (Session) -> Void = { _ in }
    var dismissHandler: () -> Void = {}
    
    init(
        authorizationService: AuthorizationService,
        cloudService: CloudService,
        sessionService: SessionService,
        theme: Theme = .light)
    {
        self.authorizationService = authorizationService
        self.cloudService = cloudService
        self.sessionService = sessionService
        self.theme = theme
        
        presentationState = presentationStateRelay
            .asDriver()
            .distinctUntilChanged()
        isWorking = isWorkingRelay.asDriver()
        link = linkRelay.asDriver()
        share = shareRelay.asDriver(onErrorDriveWith: .empty())
        
        if let userIdentifier = authorizationService.currentUser {
        sessionService
            .sessionEvents(userIdentifier: userIdentifier, events: [.add, .change, .remove])
            .subscribe(onNext: { [weak self] sessionEvent in
                switch sessionEvent {
                case .added(let session):
                    self?.sessionRelay.accept(session)
                case .changed(let session):
                    guard session == self?.sessionRelay.value else { return }
                    self?.sessionRelay.accept(session)
                case .removed:
                    self?.sessionRelay.accept(nil)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        }
        
        let session = sessionRelay.asDriver()
        
        session
            .map { session -> ShareViewPresentationState in
                if
                    let session = session,
                    session.subscriberIdentifier == nil
                {
                    return .fullscreen
                }
                return .minimized
            }
            .distinctUntilChanged()
            .drive(presentationStateRelay)
            .disposed(by: disposeBag)
        
        session
            .map { session -> String? in
                guard let session = session else {
                    return nil
                }
                return String(format: Constants.sessionURLTemplate, session.identifier)
            }
            .drive(linkRelay)
            .disposed(by: disposeBag)
        
//        session
//            .drive(onNext: { [weak self] session in
//                if let session = session, session.status == .authorized {
//                    self?.sessionAuthorizedHandler(session)
//                }
//            })
//            .disposed(by: disposeBag)
                
        presentationState.drive(onNext: { [weak self] presentationState in
            switch presentationState {
            case .fullscreen:
                self?.presentHandler()
            case .minimized:
                self?.dismissHandler()
            }
        }).disposed(by: disposeBag)
    }
    
    func present() {
        setPresentationState(.fullscreen)
        presentHandler()
    }
    
    func dismiss() {
        setPresentationState(.minimized)
        dismissHandler()
    }
    
    func setPresentationState(_ presentationState: ShareViewPresentationState) {
        presentationStateRelay.accept(presentationState)
    }
}

extension ShareViewModel {
    
    func startSession() {
        guard
            let user = authorizationService.currentUser else
        {
            return
        }
        
        guard
            let expiresAfter = SessionDurations(rawValue: durationRelay.value.row)?.timeInterval else
        {
            return
        }
        let configuration = SessionConfiguration(expiresAfter: expiresAfter, privateMode: privateRelay.value)
        
        cloudService
            .authorize()
            .andThen(cloudService.createSession(userIdentifier: user, configuration: configuration))
            .do(onSubscribe: { [isWorkingRelay] in
                isWorkingRelay.accept(true)
            }, onDispose: { [isWorkingRelay] in
                isWorkingRelay.accept(false)
            })
            .subscribe(onFailure: { error in
                print("Failed to start session: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    func endSession() {
        guard let session = sessionRelay.value else { return }
        cloudService
            .authorize()
            .andThen(cloudService.removeSession(sessionIdentifier: session.identifier))
            .subscribe(onError: { error in
                print("Unable to remove session: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    func didTapLink() {
        guard let link = linkRelay.value else { return }
        shareRelay.accept(link)
    }
}

extension ShareViewModel {
    struct Strings {
        let shareMyETA = "Share my ETA"
        let startSharing = "Start sharing"
        let cancel = "Cancel"
        let privateSwitchDescription = "Hide my location"
    }
    
    struct Constants {
        static let sessionURLTemplate = "eta://session/%@"
    }
}

extension Session: Equatable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
