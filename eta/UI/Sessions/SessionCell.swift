//
//  SessionCell.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

import RxSwift

final class SessionCell: UICollectionViewCell {
    
    var viewModel: SessionCellViewModel! { didSet { addBinds() }}
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var etaLabel: UILabel!
    
    private let authorizeView = UIView()
    
//    private var session: Session?
    private var disposeBag: DisposeBag!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        layer.masksToBounds = true
        
        authorizeView.backgroundColor = UIColor.systemRed
        authorizeView.frame = contentView.bounds
        authorizeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(authorizeView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAuthorizeView))
        authorizeView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc
    private func didTapAuthorizeView(gestureRecognized: UITapGestureRecognizer) {
        viewModel.authorizeSession()
    }
    
//    func configureWithSession(_ session: Session) {
//        switch session.status {
//        case .unauthorized:
//            titleLabel.text = "Awaiting Authorization"
//        case .authorized:
//            titleLabel.text = "Authorized"
//        }
//        
//        self.session = session
//    }
    
    private func addBinds() {
        disposeBag = DisposeBag()
        
        disposeBag.insert([
            viewModel.title.drive(titleLabel.rx.text),
            viewModel.eta.drive(etaLabel.rx.text),
            viewModel.isAuthorized.drive(authorizeView.rx.isHidden),
        ])
    }
    
    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority) -> CGSize
    {
        var targetSize = targetSize
        targetSize.height = CGFloat.greatestFiniteMagnitude
        
        let size = super.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        return size
    }
}
