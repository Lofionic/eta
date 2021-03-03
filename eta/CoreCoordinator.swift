//
//  CoreCoordinator.swift
//  eta
//
//  Created by Chris Rivers on 06/03/2021.
//

import UIKit

import RxSwift

protocol Coordinator {
    var rootViewController: UIViewController { get }
}

class CoreCoordinator: Coordinator {
    
    let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: CoreCoordinator.self))
    
    let authorizationService = FirebaseAuthorizationService()
    let cloudService = LocalCloudService()
    
    let disposeBag = DisposeBag()
    
    var navigationController: UINavigationController!
    
    init() {
        authorizationService.stateDidChange.subscribe(onNext: { [weak self] user in
            self?.authorizationStatusDidChange(user: user)
        }).disposed(by: disposeBag)
    }
    
    var rootViewController: UIViewController {
        let viewController = authenticationViewController()
        
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.isToolbarHidden = true
        return navigationController
    }
    
    func authenticationViewController() -> UIViewController {
        let viewController = AuthenticationViewController.instantiateFromStoryboard(storyboard)
        let viewModel = AuthenticationViewModel(authorizationService: authorizationService)
        viewModel.didAuthorizeHandler = { [weak self] in
            guard let self = self else { return }
            viewController.navigationController?.pushViewController(self.sessionsViewController(), animated: true)
        }
        
        viewController.viewModel = viewModel
        return viewController
    }
    
    func sessionsViewController() -> UIViewController {
        let viewController = SessionsViewController.instantiateFromStoryboard(storyboard)
        let viewModel = SessionsViewModel(authorizationService: authorizationService)
        viewModel.showUserMenuHandler = { [weak self] in
            guard let self = self else { return }
            viewController.navigationController?.pushViewController(self.userViewController(), animated: true)
        }
        viewController.viewModel = viewModel
        
        let shareViewController = ShareViewController.instantiateFromStoryboard(storyboard)
        let shareViewModel = ShareViewModel(authorizationService: authorizationService, cloudService: cloudService)
        shareViewController.viewModel = shareViewModel
        
        viewController.shareViewController = shareViewController
        
        return viewController
    }
    
    func userViewController() -> UIViewController {
        let viewController = UserViewController.instantiateFromStoryboard(storyboard)
        let viewModel = UserViewModel(authorizationService: authorizationService)
        viewController.viewModel = viewModel
        return viewController
    }
}

extension CoreCoordinator {
    
    func authorizationStatusDidChange(user: User?) {
        if user == nil {
            navigationController.popToRootViewController(animated: true)
        }
    }
}
