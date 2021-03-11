//
//  Created by Lofionic ©2021
//

import RxCocoa
import RxSwift

final class ShareViewModel: ViewModel {
    
    let presentationState: Driver<ShareViewPresentationState>
    let isWorking: Driver<Bool>
    
    private let presentationStateRelay = BehaviorRelay(value: ShareViewPresentationState.minimized)
    private let isWorkingRelay = BehaviorRelay(value: false)
    
    let authorizationService: AuthorizationService
    let cloudService: CloudService
    let theme: Theme
    
    let strings = Strings()
    let disposeBag = DisposeBag()
    
    var presentHandler: () -> Void = {}
    var dismissHandler: () -> Void = {}
    
    init(authorizationService: AuthorizationService, cloudService: CloudService, theme: Theme = .light) {
        self.authorizationService = authorizationService
        self.cloudService = cloudService
        self.theme = theme
        
        presentationState = presentationStateRelay.asDriver()
        isWorking = isWorkingRelay.asDriver()
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
        
        let _ = cloudService
            .startSession(userIdentifier: user.uid, friendIdentifier: "friend", expiresAfter: 60)
            .do(onSubscribe: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(true)
            })
            .subscribe(onCompleted: { [weak isWorkingRelay] in
                isWorkingRelay?.accept(false)
            }, onError: { [weak isWorkingRelay] error in
                print(error)
                isWorkingRelay?.accept(false)
            }).disposed(by: disposeBag)
    }
}

extension ShareViewModel {
    struct Strings {
        let shareMyETA = "Share my ETA"
    }
}
