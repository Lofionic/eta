//
//  Created by Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

final class SessionsViewController: UIViewController, StoryboardViewController {
    
    static var storyboardIdentifier = "Sessions"
    
    var viewModel: SessionsViewModel!
    var shareViewController: ShareViewController!
    
    @IBOutlet var userButton: UIButton!
    @IBOutlet var shareTray: Tray!
    
    override func viewDidLoad() {
        addShareViewController()
    }
    
    @IBAction func didTapUserButton(_ sender: Any) {
        viewModel.didTapUserButton()
    }
}

private extension SessionsViewController {
    
    func addShareViewController() {
        shareViewController.view.frame = shareTray.bounds
        shareViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shareTray.addSubview(shareViewController.view)
        addChild(shareViewController)
    }
}

extension SessionsViewController: TrayDelegate {
    func tray(_ tray: Tray, restingHeightForHeight offset: CGFloat, velocity: CGFloat) -> CGFloat {
        let bottomOfHeader = shareViewController.view.convert(shareViewController.headerView.frame, to: shareViewController.view).maxY
        let bottomOfBody = shareViewController.view.convert(shareViewController.bodyView.frame, to: shareViewController.view).maxY
        
        if velocity < -10 {
            return bottomOfBody
        }

        if velocity > 10 {
            return bottomOfHeader
        }
        
        let normalized = (offset - bottomOfHeader) / (bottomOfBody - bottomOfHeader)
        return normalized > 0.5 ? bottomOfBody : bottomOfHeader
    }
    
    func minimumPanningOffsetForTray(_ tray: Tray) -> CGFloat {
        return view.convert(shareViewController.headerView.frame, to: view).maxY * 0.5
    }
    
    func maximumPanningOffsetForTray(_ tray: Tray) -> CGFloat {
        return view.convert(shareViewController.bodyView.frame, to: view).maxY * 1.1
    }
}
