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
    
    override func viewDidLoad() {
    }
    
    @IBAction func didTapUserButton(_ sender: Any) {
        viewModel.didTapUserButton()
    }
}
