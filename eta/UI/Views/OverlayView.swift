//
//  Lofionic ©2021
//

import UIKit

final class OverlayView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    private func commonSetup() {
        layer.cornerRadius = 4
//        layer.borderColor = UIColor.systemGray2.cgColor
//        layer.borderWidth = 0.5
        layer.masksToBounds = false
        layer.shadowRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 3.0)
    }
}
