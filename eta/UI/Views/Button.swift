//
//  Created by Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

@IBDesignable
final class Button: UIButton {
    
    private let activityIndicator = UIActivityIndicatorView()
    
    override var backgroundColor: UIColor? {
        didSet{
            activityIndicator.backgroundColor = backgroundColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyling()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyling()
    }
    
    private func setupStyling() {
        layer.masksToBounds = true
        
        activityIndicator.frame = bounds
        activityIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = tintColor
        activityIndicator.backgroundColor = backgroundColor

        addSubview(activityIndicator)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        activityIndicator.color = tintColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shortestDimension = min(frame.width, frame.height)
        layer.cornerRadius = shortestDimension / 2.0
        
        bringSubviewToFront(activityIndicator)
    }
}

extension Button {
    func startAnimatingActivityIndicator() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.stopAnimating()
    }
}

extension Button {
    struct Colors {
        static let background = UIColor.white
    }
}

extension Reactive where Base == Button {
    
    var isAnimatingActivityIndicator: Binder<Bool> {
        return Binder<Bool>(base) { base, isAnimatingActivityIndicator  in
            if isAnimatingActivityIndicator {
                base.startAnimatingActivityIndicator()
            } else {
                base.stopAnimatingActivityIndicator()
            }
        }
    }
}
