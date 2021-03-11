//
//  Created by Lofionic ©2021
//

import CoreGraphics

extension CGRect {
	
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
	
	init(center: CGPoint, size: CGSize) {
		self.init(
			origin: CGPoint(x: center.x - size.width / 2.0, y: center.y - size.height / 2.0),
			size: size)
	}
}

