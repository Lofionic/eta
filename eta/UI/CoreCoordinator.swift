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
    let databaseService = FirebaseDatabaseService()
    
    #if targetEnvironment(simulator)
    let cloudService = RemoteCloudService(scheme: .http, domain: "127.0.0.1", port: 8080)
    #else
    let cloudService = RemoteCloudService(scheme: .https, domain: "lofionic-eta.herokuapp.com")
    #endif
    
    let disposeBag = DisposeBag()
    
    var locationController: LocationController?
    
    var navigationController: UINavigationController!
    
    init() {
        authorizationService.stateDidChange.subscribe(onNext: { [weak self] userIdentifier in
            self?.authorizationStatusDidChange(userIdentifier: userIdentifier)
        }).disposed(by: disposeBag)
        
        cloudService.authenticationService = authorizationService
    }
    
    var rootViewController: UIViewController {
        let viewController = authenticationViewController()
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.isToolbarHidden = true
        
        if authorizationService.currentUser != nil {
            navigationController.pushViewController(sessionsViewController(), animated: false)
        }
        
        return navigationController
    }
    
    func authenticationViewController() -> UIViewController {
        let viewController = AuthenticationViewController.instantiateFromStoryboard(storyboard)
        let viewModel = AuthenticationViewModel(authorizationService: authorizationService)
        viewModel.signInHandler = { [weak self] _ in
            guard let self = self else { return }
            self.navigationController.pushViewController(self.sessionsViewController(), animated: true)
        }
        viewModel.registerHandler = { [weak self] in
            guard let self = self else { return }
            self.navigationController.pushViewController(self.registerViewController(), animated: true)
        }
        
        viewController.viewModel = viewModel
        return viewController
    }
    
    func registerViewController() -> UIViewController {
        let viewController = RegisterViewController.instantiateFromStoryboard(storyboard)
        let viewModel = RegisterViewModel(authorizationService: authorizationService, cloudService: cloudService)
        viewModel.registerHandler = { [weak self] _ in
            guard let self = self else { return }
            self.navigationController.pushViewController(self.sessionsViewController(), animated: true)
        }
        
        viewModel.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.navigationController.popViewController(animated: true)
        }
        viewController.viewModel = viewModel
        return viewController
    }
    
    func sessionsViewController() -> UIViewController {
        let viewController = SessionsViewController.instantiateFromStoryboard(storyboard)
        let viewModel = SessionsViewModel(
            authorizationService: authorizationService,
            sessionService: databaseService,
            userService: databaseService,
            cloudService: cloudService)
        viewModel.showUserMenuHandler = { [weak self] in
            guard let self = self else { return }
            self.navigationController.present(self.userViewController(), animated: true)
        }
        viewModel.hostingSessionHandler = { [weak self] session in
            guard let self = self else { return }
            let sharingViewController = self.sharingViewController(session: session)
            self.navigationController.pushViewController(sharingViewController, animated: true)
        }
        viewController.viewModel = viewModel
        
        let shareViewController = ShareViewController.instantiateFromStoryboard(storyboard)
        let shareViewModel = ShareViewModel(
            authorizationService: authorizationService,
            cloudService: cloudService,
            sessionService: databaseService)
        shareViewModel.presentHandler = { [weak viewModel] in
            viewModel?.setShowingShareView(true)
        }
        shareViewModel.dismissHandler = { [weak viewModel] in
            viewModel?.setShowingShareView(false)
        }
        shareViewModel.sessionAuthorizedHandler = { session in
            print("Session authorized: \(session.identifier)")
        }
        shareViewController.viewModel = shareViewModel
        
        viewModel.embedShareViewControllerHandler = {
            return shareViewController
        }
        
        return viewController
    }
    
    func sharingViewController(session: Session) -> UIViewController {
        let viewController = SharingViewController.instantiateFromStoryboard(self.storyboard)
        let viewModel = SharingViewModel(
            sessionIdentifier: session.identifier,
            sessionService: self.databaseService,
            userService: self.databaseService,
            cloudService: self.cloudService)
        viewModel.sharingEndedHandler = {
            viewController.navigationController?.popViewController(animated: true)
        }
        viewController.viewModel = viewModel
        return viewController
    }
    
    func userViewController() -> UIViewController {
        let viewController = UserViewController.instantiateFromStoryboard(storyboard)
        let viewModel = UserViewModel(userService: databaseService, authorizationService: authorizationService)
        viewController.viewModel = viewModel
        return viewController
    }
}

extension CoreCoordinator {
    
    func authorizationStatusDidChange(userIdentifier: String?) {
        if let userIdentifier = userIdentifier {
            locationController = LocationController(
                userIdentifier: userIdentifier,
                sessionService: databaseService,
                cloudService: cloudService,
                authorizationService: authorizationService)
        } else {
            locationController = nil
            navigationController.popToRootViewController(animated: true)
        }
    }
}
