//
//  Lofionic ©2021
//

import MapKit
import UIKit

import RxCocoa
import RxSwift

final class SharingViewController: UIViewController, StoryboardViewController {
	static let storyboardIdentifier = "Sharing"
	var viewModel: SharingViewModel!
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var detailContainer: UIView!
    
    @IBOutlet private var sharingTitle: UILabel!
    @IBOutlet private var sharingLabel: UILabel!
    
    @IBOutlet private var destinationTitle: UILabel!
    @IBOutlet private var destinationLabel: UILabel!
    
    @IBOutlet private var etaTitle: UILabel!
    @IBOutlet private var etaLabel: UILabel!
    
    @IBOutlet private var stopSharingButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBinds()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let mapMargins = UIEdgeInsets(
            top: detailContainer.frame.maxY,
            left: 0,
            bottom: view.bounds.maxY - stopSharingButton.frame.minX,
            right: 0)
        mapView.layoutMargins = mapMargins
    }
    
    private func setupBinds() {
        disposeBag.insert([
            viewModel.eta.drive(etaLabel.rx.text),
            viewModel.subscriberUsername.drive(sharingLabel.rx.text),
        ])
    }
    
    @IBAction
    private func didTapStopSharing(_ sender: Any) {
        viewModel.endSession()
    }
}
