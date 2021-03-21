//
//  Created by Lofionic ©2021
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
    @IBOutlet var collectionView: UICollectionView!
    
    private var sessions = [Session]()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme = viewModel.theme
        userButton.tintColor = theme.colors.tint
        
        embedShareViewController()
        setBinds()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize(
                width: collectionView.widestCellWidth,
                height: 200
            )
        }
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
            collectionView.performBatchUpdates() {
                sessions.append(session)
                sessions.sort(by: { a, b in a.startDate > b.startDate })
                if let index = sessions.firstIndex(where: { $0.identifier == session.identifier }) {
                    collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
                }
            }
        case .removed(let session):
            collectionView.performBatchUpdates() {
                if let index = sessions.firstIndex(where: { $0.identifier == session.identifier }) {
                    sessions.remove(at: index)
                    collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
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
        
        showShareViewControllerConstraint = shareViewControllerContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        showShareViewControllerConstraint.priority = .required
    }
}

extension SessionsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        if let sessionCell = cell as? SessionCell {
            let cellViewModel = viewModel.viewModelForSession(sessions[indexPath.row])
            sessionCell.viewModel = cellViewModel
        }
        
        return cell
    }
}

extension UICollectionView {
    var widestCellWidth: CGFloat {
        let insets = contentInset.left + contentInset.right
        
        let sectionInsets: CGFloat
        if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            sectionInsets = flowLayout.sectionInset.left + flowLayout.sectionInset.right
        } else {
            sectionInsets = 0
        }
        
        return bounds.width - insets - sectionInsets
    }
}
