//
//  StyleCatalog.swift
//  eta
//
//  Created by Chris Rivers on 09/03/2021.
//

import UIKit

struct Theme {
    
    struct Colors {
        let primary: UIColor
        let background: UIColor
        let tint: UIColor
    }
    
    struct Fonts {
        let body: UIFont
        let button: UIFont
        
        init() {
            body = UIFont.preferredFont(forTextStyle: .body)
            button = UIFont.preferredFont(forTextStyle: .body)
        }
    }
    
    let colors: Colors
    let fonts: Fonts
    
    static let light: Theme = {
        let colors = Colors(
            primary: UIColor.systemGray,
            background: UIColor.systemGray6,
            tint: UIColor(hexString: "#407ADF"))
        
        return Theme(colors: colors, fonts: Fonts())
    }()
}

private extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
