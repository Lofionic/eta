//
//  Created by Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

final class ShareViewController: UIViewController, StoryboardViewController {
    
    static var storyboardIdentifier = "Share"
    
    var viewModel: ShareViewModel!
    
    @IBOutlet private(set) var headerView: UIView!
    @IBOutlet private(set) var bodyView: UIView!
    @IBOutlet private var button: Button!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBinds()
    }
    
    private func addBinds() {
        disposeBag.insert([
            viewModel.isWorking.drive(button.rx.isAnimatingActivityIndicator)
        ])
    }
    
    @IBAction func didTapStartSession(_ sender: Any) {
        viewModel.startSession()
    }
}
