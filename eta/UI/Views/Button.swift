//
//  Created by Lofionic ©2021
//

import UIKit

import RxCocoa
import RxSwift

final class Button: UIButton {
    
    private let activityIndicator = UIActivityIndicatorView()
    private let maskLayer = MaskLayer()
    
    override var backgroundColor: UIColor? {
        didSet{
            activityIndicator.backgroundColor = backgroundColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    private func commonSetup() {
        layer.mask = maskLayer
        
        activityIndicator.frame = bounds
        activityIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = tintColor
        activityIndicator.backgroundColor = backgroundColor
        addSubview(activityIndicator)
        
        titleLabel?.adjustsFontForContentSizeCategory = true
        
        applyTheme(Theme.light)
    }
    
    public func applyTheme(_ theme: Theme) {
        backgroundColor = theme.colors.tint
        titleLabel?.font = theme.fonts.button
		
		tintColor = UIColor.white
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        activityIndicator.color = tintColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bringSubviewToFront(activityIndicator)
        
        maskLayer.frame = layer.bounds
    }
}

extension Button {
    func startAnimatingActivityIndicator() {
        guard !activityIndicator.isAnimating else { return }
        activityIndicator.startAnimating()
        
        maskLayer.removeAnimation(forKey: "animation")
        let animation = CABasicAnimation(keyPath: "animationProgress")
        animation.fromValue = maskLayer.presentation()?.animationProgress ?? 0
        animation.toValue = 1
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        maskLayer.add(animation, forKey: "lfResizeMaskAnimation")
        maskLayer.animationProgress = 1
    }
    
    func stopAnimatingActivityIndicator() {
        guard activityIndicator.isAnimating else { return }
        activityIndicator.stopAnimating()
        
        maskLayer.removeAnimation(forKey: "animation")
        let animation = CABasicAnimation(keyPath: "animationProgress")
        animation.fromValue = maskLayer.presentation()?.animationProgress ?? 1
        animation.toValue = 0
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        maskLayer.add(animation, forKey: "lfResizeMaskAnimation")
        maskLayer.animationProgress = 0
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

private final class MaskLayer: CALayer {
    
    @NSManaged var animationProgress: CGFloat
    
    override var needsDisplayOnBoundsChange: Bool {
        get { return true }
        set {}
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "animationProgress" {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext) {		
        let openRect = bounds
        
        let smallestDimension = min(bounds.width, bounds.height)
        let ellipseRadius = smallestDimension / 2
        
        let closedRect = CGRect(
            origin: CGPoint(x: bounds.midX - ellipseRadius, y: bounds.midY - ellipseRadius),
            size: CGSize(width: smallestDimension, height: smallestDimension))
        
        let rect = openRect.lerp(closedRect, value: animationProgress)
        let cornerRadius = CGFloat(4).lerp(ellipseRadius, value: animationProgress)
        
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
    }
}
