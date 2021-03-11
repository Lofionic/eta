//
//  Created by Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

enum ShareViewPresentationState {
    case minimized
    case fullscreen
}

final class ShareViewController: UIViewController, StoryboardViewController {
    
    static var storyboardIdentifier = "Share"
    var viewModel: ShareViewModel!
    
    @IBOutlet private(set) var headerView: UIView!
    @IBOutlet private(set) var bodyView: UIView!
    @IBOutlet private var presentButton: Button!
    @IBOutlet private var dismissButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyView.backgroundColor = viewModel.theme.colors.background
        presentButton.setTitle(viewModel.strings.shareMyETA, for: .normal)
        
        setPresentationState(.minimized, animated: false)
        addBinds()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeFromParent()
    }
    
    private func addBinds() {
        disposeBag.insert([
            viewModel.presentationState.skip(1).drive(onNext: { [weak self] presentationState in
                self?.setPresentationState(presentationState, animated: true)
            }),
            viewModel.isWorking.drive(presentButton.rx.isAnimatingActivityIndicator)
        ])
    }
    
    private func setPresentationState(_ presentationState: ShareViewPresentationState, animated: Bool) {
        switch presentationState {
        case .minimized:
            if animated {
                fadeViews(hidingView: bodyView, showingView: headerView, withDuration: SessionsViewController.presentShareViewAnimationDuration)
            } else {
                bodyView.isHidden = true
                headerView.isHidden = false
            }
        case .fullscreen:
            if animated {
                fadeViews(hidingView: headerView, showingView: bodyView, withDuration: SessionsViewController.presentShareViewAnimationDuration)
            } else {
                bodyView.isHidden = false
                headerView.isHidden = true
            }
        }
    }
    
    private func animatePresentationState(_ presentationState: ShareViewPresentationState) {
        switch presentationState {
        case .minimized:
            fadeViews(hidingView: bodyView, showingView: headerView, withDuration: 1)
        case .fullscreen:
            fadeViews(hidingView: headerView, showingView: bodyView, withDuration: 1)
        }
    }
    
    private func fadeViews(hidingView: UIView, showingView: UIView, withDuration duration: TimeInterval) {
        [hidingView, showingView].forEach { $0.isHidden = false }
        
        hidingView.alpha = 1
        showingView.alpha = 0
        UIView.animate(withDuration: duration, animations: {
            hidingView.alpha = 0
            showingView.alpha = 1
        }, completion: { _ in
            hidingView.isHidden = true
            showingView.isHidden = false
            [hidingView, showingView].forEach { $0.alpha = 1 }
        })
    }
}

extension ShareViewController {
    @IBAction func didTapPresent(_ sender: Any) {
        viewModel.present()
    }
    
    @IBAction func didTapDismiss(_ sender: Any) {
        viewModel.dismiss()
    }
}
