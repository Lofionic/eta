//
//  Created by Lofionic ©2021
//

import CoreGraphics

protocol CGInterpolates {
	func lerp(_ other: Self, value: CGFloat) -> Self
}

extension CGFloat: CGInterpolates {
	func lerp(_ other: Self, value: CGFloat) -> Self {
		return self + (other - self) * value
	}
}

extension CGPoint: CGInterpolates {
	func lerp(_ other: Self, value: CGFloat) -> Self {
		return CGPoint(
			x: x.lerp(other.x, value: value),
			y: y.lerp(other.y, value: value))
	}
}

extension CGSize: CGInterpolates {
	func lerp(_ other: Self, value: CGFloat) -> Self {
		return CGSize(
			width: width.lerp(other.width, value: value),
			height: height.lerp(other.height, value: value))
	}
}

extension CGRect: CGInterpolates {
	func lerp(_ other: Self, value: CGFloat) -> Self {
		return CGRect(
			origin: origin.lerp(other.origin, value: value),
			size: size.lerp(other.size, value: value))
	}
}
