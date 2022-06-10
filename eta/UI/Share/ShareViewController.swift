//
//  Lofionic ©2021
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
    
	@IBOutlet private var durationPicker: UIPickerView!
    @IBOutlet private var privateSwitch: UISwitch!
    @IBOutlet private var privateLabel: UILabel!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private(set) var stackView: UIStackView!
    
    private let sessionLinkView = SessionLinkView()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyView.backgroundColor = viewModel.theme.colors.background
        presentButton.setTitle(viewModel.strings.shareMyETA, for: .normal)
        
        sessionLinkView.setButtonTitle(viewModel.strings.startSharing, for: .normal)
        sessionLinkView.tapButtonHandler = { [weak self] in
            self?.viewModel.startSession()
        }
        sessionLinkView.tapLinkHandler = { [weak self] _ in
            self?.viewModel.didTapLink()
        }
        
        titleLabel.text = viewModel.strings.shareMyETA
        stackView.insertArrangedSubview(sessionLinkView, at: 3)
        
        privateLabel.text = viewModel.strings.privateSwitchDescription
        privateSwitch.onTintColor = viewModel.theme.colors.tint
        
        dismissButton.tintColor = viewModel.theme.colors.tint
        
        setPresentationState(.minimized, animated: false)
        addBinds()
        
        durationPicker.selectRow(viewModel.durationRelay.value.row, inComponent: 0, animated: false)
    }
    
    private func addBinds() {
        disposeBag.insert([
            viewModel.presentationState.skip(1).drive(rx.presdentationState),
            viewModel.link.drive(sessionLinkView.rx.link),
            viewModel.isWorking.not().drive(sessionLinkView.rx.isEnabled),
            viewModel.isWorking.not().drive(dismissButton.rx.isEnabled),
            viewModel.isWorking.drive(sessionLinkView.rx.isAnimatingActivityIndicator),
        ])
        
        disposeBag.insert([
            viewModel.durationOptions.bind(to: durationPicker.rx.itemTitles) { $1 },
            durationPicker.rx.itemSelected.bind(to: viewModel.durationRelay),
            privateSwitch.rx.isOn <-> viewModel.privateRelay,
        ])
        
        Driver.combineLatest(viewModel.isWorking, viewModel.link) {
            $0 || $1 != nil
        }.drive(onNext: { [weak self] sessionStarted in
            self?.durationPicker.isUserInteractionEnabled = !sessionStarted
            self?.durationPicker.alpha = sessionStarted ? 0.5 : 1
            
            self?.privateSwitch.isEnabled = !sessionStarted
            self?.privateSwitch.alpha = sessionStarted ? 0.5 : 1
            
            self?.privateLabel.alpha = sessionStarted ? 0.5 : 1
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
            durationPicker.selectRow(durationPicker.numberOfRows(inComponent: 0) / 2, inComponent: 0, animated: false)
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
