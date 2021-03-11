//
//  IrisTransition.swift
//  eta
//
//  Created by Chris Rivers on 10/03/2021.
//

import UIKit

final class IrisTransition: NSObject, UIViewControllerAnimatedTransitioning {
	
	let startRectangle: CGRect
	
	init(startRectangle: CGRect) {
		self.startRectangle = startRectangle
	}
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.2
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard
			let fromViewController = transitionContext.viewController(forKey: .from),
			let toViewController = transitionContext.viewController(forKey: .to),
			let fromView = transitionContext.view(forKey: .from),
			let toView = transitionContext.view(forKey: .to) else
		{
			return
		}
		
		let containerView = transitionContext.containerView
		fromView.frame = transitionContext.initialFrame(for: fromViewController)
		containerView.addSubview(fromView)
		
		toView.frame = transitionContext.finalFrame(for: toViewController)
		containerView.addSubview(toView)
		
		let maskLayer = MaskLayer()
		maskLayer.startRect = startRectangle
		maskLayer.frame = toView.bounds
		toView.layer.mask = maskLayer
		
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "animationProgress")
		animation.fromValue = 0
		animation.toValue = 1
		animation.fillMode = .forwards
		animation.duration = transitionDuration(using: transitionContext)
		
		CATransaction.setCompletionBlock {
			toView.layer.mask = nil
			transitionContext.completeTransition(true)
		}
		maskLayer.add(animation, forKey: "maskAnimation")
		CATransaction.commit()
	}
	
	private final class MaskLayer: CALayer {
		
		@NSManaged var animationProgress: CGFloat
		@NSManaged var startRect: CGRect
		@NSManaged var endRect: CGRect
		
		override var needsDisplayOnBoundsChange: Bool {
			get { return true }
			set {}
		}
		
		override var bounds: CGRect {
			didSet {
				let endDiameter = sqrt(pow(bounds.mid.x, 2) + pow(bounds.mid.y, 2)) * 2
				endRect = CGRect(
					center: bounds.mid,
					size: CGSize(width: endDiameter, height: endDiameter))
			}
		}
		
		override class func needsDisplay(forKey key: String) -> Bool {
			if key == "animationProgress" {
				return true
			}
			
			return super.needsDisplay(forKey: key)
		}
		
		override func draw(in ctx: CGContext) {
			let rect = startRect.lerp(endRect, value: animationProgress)
			ctx.fillEllipse(in: rect)
		}
	}
}
