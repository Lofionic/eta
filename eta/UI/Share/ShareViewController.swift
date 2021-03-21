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
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var startButton: Button!
    @IBOutlet private var sessionLinkLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyView.backgroundColor = viewModel.theme.colors.background
        presentButton.setTitle(viewModel.strings.shareMyETA, for: .normal)
        
        let tapLinkGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLink(_:)))
        sessionLinkLabel.addGestureRecognizer(tapLinkGesture)
        sessionLinkLabel.isUserInteractionEnabled = true
        
        setPresentationState(.minimized, animated: false)
        addBinds()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        viewModel.endSession()
        removeFromParent()
    }
    
    private func addBinds() {
        disposeBag.insert([
            viewModel.presentationState.skip(1).drive(rx.presdentationState),
            viewModel.link.drive(sessionLinkLabel.rx.text),
            viewModel.isWorking.not().drive(startButton.rx.isEnabled),
            viewModel.isWorking.not().drive(dismissButton.rx.isEnabled),
            viewModel.isWorking.drive(startButton.rx.isAnimatingActivityIndicator),
        ])
        
        viewModel.link.drive(onNext: { [weak self] link in
            guard let self = self else { return }
            if link != nil {
                self.startButton.isHidden = true
                self.sessionLinkLabel.isHidden = false
            } else {
                self.startButton.isHidden = false
                self.sessionLinkLabel.isHidden = true
            }
        }).disposed(by: disposeBag)
        
        viewModel.share.drive(onNext: { [weak self] item in
            let shareViewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
            self?.present(shareViewController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func setPresentationState(_ presentationState: ShareViewPresentationState, animated: Bool) {
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
        viewModel.endSession()
        viewModel.dismiss()
    }
    
    @IBAction func didTapStart(_ sender: Any) {
        viewModel.startSession()
    }
    
    @IBAction func didTapLink(_ sender: Any) {
        viewModel.didTapLink()
    }
}

extension Reactive where Base == ShareViewController {
    var presdentationState: Binder<ShareViewPresentationState> {
        return Binder<ShareViewPresentationState>(base) { base, presentationState in
            base.setPresentationState(presentationState, animated: true)
        }
    }
}
