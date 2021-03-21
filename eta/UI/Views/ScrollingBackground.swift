//
//  ScrollingBackground.swift
//  eta
//
//  Created by Chris Rivers on 11/03/2021.
//

import UIKit

final class ScrollingBackground: UIView {
	
	public var image: UIImage? {
		didSet {
			guard let scrollingLayer = layer as? HorizontalScrollingLayer else { return }
			scrollingLayer.image = image?.cgImage
		}
	}
	
	public var animationDuration: TimeInterval = 20
	
	override class var layerClass: AnyClass { HorizontalScrollingLayer.self }
	
	private var displayLink: CADisplayLink?
	
	private func commonSetup() {
	}
	
	func resumeScrolling() {
        pauseScrolling()
		
		let displayLink = CADisplayLink(target: self, selector: #selector(update))
		displayLink.add(to: .current, forMode: .common)
		
		self.displayLink = displayLink
	}
	
	func pauseScrolling() {
		displayLink?.invalidate()
        displayLink = nil
	}
	
	@objc
	private func update() {
		guard let scrollingLayer = layer as? HorizontalScrollingLayer else { return }
		scrollingLayer.phase += CGFloat(1 / (60 * animationDuration)).truncatingRemainder(dividingBy: 1)
	}
	
	private class HorizontalScrollingLayer: CALayer {
		
		@NSManaged var image: CGImage?
		@NSManaged var phase: CGFloat
		
		override var needsDisplayOnBoundsChange: Bool {
			get { return true }
			set {}
		}
		
		override class func needsDisplay(forKey key: String) -> Bool {
			if key == "phase" || key == "image" {
				return true
			}
			return super.needsDisplay(forKey: key)
		}
		
		override func draw(in ctx: CGContext) {
			guard let image = image else { return }
			
			let aspectRatio = CGFloat(image.width / image.height)
			let drawSize = CGSize(width: bounds.height * aspectRatio, height: bounds.height)
			
			let offset = phase * drawSize.width
			var drawRect = CGRect(origin: CGPoint(x: -offset, y: 0), size: drawSize)
			
			while drawRect.minX < bounds.maxX {
				ctx.draw(image, in: drawRect)
				drawRect = drawRect.offsetBy(dx: drawRect.width - 1, dy: 0)
			}
		}
	}
}
