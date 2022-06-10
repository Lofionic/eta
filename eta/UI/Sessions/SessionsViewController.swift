//
//  Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

final class SessionsViewController: UIViewController, StoryboardViewController {
    
    static var storyboardIdentifier = "Sessions"
    
    var viewModel: SessionsViewModel!
    
    var shareViewControllerConstraint: NSLayoutConstraint!
    var showShareViewControllerConstraint: NSLayoutConstraint!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var userButton: UIButton!
    @IBOutlet var shareViewControllerContainer: UIView!
    @IBOutlet var tableView: UITableView!
    
    private let maskingView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    private var sessions = [Session]()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme = viewModel.theme
        userButton.tintColor = theme.colors.tint
        
        maskingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maskingView.frame = view.bounds
        maskingView.alpha = 0
        view.insertSubview(maskingView, belowSubview: shareViewControllerContainer)
        
        embedShareViewController()
        setBinds()
    }
    
    private func setBinds() {
        viewModel.isShowingShareView.skip(1).drive(onNext: { [weak self] isShowingShareView in
            guard let showShareViewControllerConstraint = self?.showShareViewControllerConstraint else {
                return
            }
            if isShowingShareView {
                NSLayoutConstraint.activate([showShareViewControllerConstraint])
            } else {
                NSLayoutConstraint.deactivate([showShareViewControllerConstraint])
            }
            UIView.animate(withDuration: Self.presentShareViewAnimationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
                self?.maskingView.alpha = isShowingShareView ? 1 : 0
            }
            self?.playHapticFeedback()
        }).disposed(by: disposeBag)

        viewModel.sessionsEvents.drive(onNext: { [weak self] event in
            self?.handleSessionEvent(event)
        }).disposed(by: disposeBag)
    }
    
    private func handleSessionEvent(_ event: DataEvent<Session>) {
        switch event {
        case .added(let session):
            tableView.performBatchUpdates() {
                sessions.append(session)
                sessions.sort(by: { a, b in a.startDate > b.startDate })
                if let index = sessions.firstIndex(where: { $0.identifier == session.identifier }) {
                    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .left)
                }
            }
        case .removed(let session):
            tableView.performBatchUpdates() {
                if let index = sessions.firstIndex(where: { $0.identifier == session.identifier }) {
                    sessions.remove(at: index)
                    tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: .left)
                }
            }
        default: break
        }
    }
    
    private func playHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }
    
    @IBAction func didTapUserButton(_ sender: Any) {
        viewModel.didTapUserButton()
    }
}

extension SessionsViewController {
    static let presentShareViewAnimationDuration = 0.3
    
    private func embedShareViewController() {
        
        guard
            let viewController = viewModel.embedShareViewControllerHandler(),
            let shareViewController = viewController as? ShareViewController else
        {
            return
        }
        
        shareViewController.view.frame = shareViewControllerContainer.bounds
        shareViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shareViewControllerContainer.addSubview(shareViewController.view)
        addChild(shareViewController)

        shareViewControllerConstraint = shareViewController.headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        shareViewControllerConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([shareViewControllerConstraint])
        
        showShareViewControllerConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shareViewController.stackView.bottomAnchor, constant:8)
//        showShareViewControllerConstraint = shareViewControllerContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        showShareViewControllerConstraint.priority = .required
    }
}

extension SessionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let sessionCell = cell as? SessionCell {
            let cellViewModel = viewModel.viewModelForSession(sessions[indexPath.row])
            sessionCell.viewModel = cellViewModel
        }
        
        return cell
    }
}
