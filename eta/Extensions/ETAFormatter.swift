//
//  Lofionic ©2021
//

import Foundation

extension DateComponentsFormatter {
    
    static var eta: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2
        return formatter
    }
}
