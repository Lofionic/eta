//
//  SessionCell.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

final class SessionCell: UICollectionViewCell {
    
    @IBOutlet private var titleLabel: UILabel!
    
    var session: Session?
    
    func configureWithSession(_ session: Session) {
        titleLabel.text = session.identifier
        
        self.session = session
    }
    
    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority) -> CGSize {
        
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
