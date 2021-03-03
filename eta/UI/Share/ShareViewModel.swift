//
//  Created by Lofionic ©2021
//

import RxCocoa
import RxSwift

final class ShareViewModel: ViewModel {
    
    let isWorking: Driver<Bool>
    private let isWorkingRelay = BehaviorRelay(value: false)
    
    let authorizationService: AuthorizationService
    let cloudService: CloudService
    
    let disposeBag = DisposeBag()
    
    init(authorizationService: AuthorizationService, cloudService: CloudService) {
        self.authorizationService = authorizationService
        self.cloudService = cloudService
        
        isWorking = isWorkingRelay.asDriver()
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
