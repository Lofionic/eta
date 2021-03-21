//
//  Created by Lofionic ©2021
//

import FirebaseAuth
import RxCocoa
import RxSwift

final class ShareViewModel: ViewModel {
    
    let presentationState: Driver<ShareViewPresentationState>
    let isWorking: Driver<Bool>
    let link: Driver<String?>
    let share: Driver<Any>
        
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
                if session != nil {
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
        
        cloudService
            .authorize()
            .andThen(cloudService.createSession(userIdentifier: user))
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
