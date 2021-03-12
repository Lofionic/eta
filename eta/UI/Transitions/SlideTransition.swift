//
//  SlideUpTransition.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

enum SlideTransitionDirection {
	case slideUp
	case slideDown
}

final class SlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
	
	private let direction: SlideTransitionDirection
	
	init(direction: SlideTransitionDirection) {
		self.direction = direction
	}
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.5
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
		
		switch direction {
		case .slideUp:
			toView.frame.origin = CGPoint(x: toView.frame.origin.x, y: fromView.frame.height)
		case .slideDown:
			toView.frame.origin = CGPoint(x: toView.frame.origin.x, y: -toView.frame.height)
		}
		
		UIView.animate(
			withDuration: transitionDuration(using: transitionContext),
			animations: { [direction] in
				toView.frame = transitionContext.finalFrame(for: toViewController)
				switch direction {
				case .slideUp:
					fromView.frame = fromView.frame.offsetBy(dx: 0, dy: -containerView.frame.height)
				case .slideDown:
					fromView.frame = fromView.frame.offsetBy(dx: 0, dy: containerView.frame.height)
				}
				
			}, completion: { didComplete in
				transitionContext.completeTransition(didComplete)
			})
	}
}
