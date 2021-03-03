//
//  Created by Lofionic ©2021
//

import UIKit

@IBDesignable
final class HandleView: UIView {
    
    private let handleSize = CGSize(width: 44, height: 4)
    private let fillColor = UIColor(white: 0.9, alpha: 1)
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let horizontalInset = (rect.width - handleSize.width) / 2
        let verticalInset = (rect.height - handleSize.height) / 2
        
        let insetRect = rect.inset(by: UIEdgeInsets(
                                    top: verticalInset,
                                    left: horizontalInset,
                                    bottom: verticalInset,
                                    right: horizontalInset))
        
        context.setFillColor(fillColor.cgColor)
        
        let path = CGPath(roundedRect: insetRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        context.addPath(path)
        context.fillPath()
    }

}
