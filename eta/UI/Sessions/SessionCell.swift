//
//  Lofionic ©2021
//

import UIKit

import RxSwift

final class SessionCell: UITableViewCell {
    
    var viewModel: SessionCellViewModel! { didSet { addBinds() }}
    
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var etaLabel: UILabel!
    @IBOutlet private var avatar: AvatarView!
    
    private let authorizeView = UIView()
    
    private var disposeBag: DisposeBag!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
            viewModel.username.drive(usernameLabel.rx.text),
            viewModel.user.drive(avatar.rx.user),
            viewModel.title.drive(titleLabel.rx.text),
            viewModel.eta.drive(etaLabel.rx.text),
            viewModel.isAuthorized.drive(authorizeView.rx.isHidden),
        ])
        
        etaLabel.textColor = viewModel.theme.colors.tint
    }
}
