//
//  Avatar.swift
//  eta
//
//  Created by Chris Rivers on 21/03/2021.
//

import UIKit

import RxSwift

@IBDesignable
final class AvatarView: UIView {
    
    let theme = Theme.light
    
    var user: User? = nil {
        didSet {
            setNeedsDisplay()
        }}
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let diameter = min(rect.width, rect.height)
        let rect = CGRect(center: rect.mid, size: CGSize(width: diameter, height: diameter))
        
        context.addEllipse(in: rect)
        context.clip()
        
//        context.setFillColor(theme.colors.tint.cgColor)
//        context.fill(rect)
        
        if
            let user = user
        {
            let username = user.username ?? user.email
            let backgroundColor = generateAlternativeColorFor(text: username, saturation: 0.5, brightness: 0.5)
            context.setFillColor(backgroundColor.cgColor)
            context.fill(rect)
            
            let radius = diameter / 2.0
            let foo = radius * sqrt(2)
            let textRect = CGRect(center: rect.mid, size: CGSize(width: diameter, height: foo))
            
            let foregroundColor = generateAlternativeColorFor(text: username, saturation: 0.25, brightness: 1.0)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let string = generateAbbreviationForText(username)
            let font = largestSystemFontSize(text: string, paragraphStyle: paragraphStyle, rect: textRect)
            
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: foregroundColor,
                NSAttributedString.Key.font: font,
                
            ]
            
            let offsetRect = textRect.offsetBy(dx: 0, dy: 0)
            let attributedString = NSAttributedString(string: string, attributes: attributes)
            attributedString.draw(with: offsetRect, options: [.usesLineFragmentOrigin], context: nil)
        }
    }
}

private func generateColorFor(text: String, saturation: CGFloat, brightness: CGFloat) -> UIColor{
    var hash = 0
    let colorConstant = 131
    let maxSafeValue = Int.max / colorConstant
    for char in text.unicodeScalars{
        if hash > maxSafeValue {
            hash = hash / colorConstant
        }
        hash = Int(char.value) + ((hash << 5) - hash)
    }
    let finalHash = abs(hash) % (256*256*256);
    let color = UIColor(
        hue:CGFloat(finalHash)/255.0 ,
        saturation: saturation,
        brightness: brightness,
        alpha: 1.0)
    return color
}

private func generateAlternativeColorFor(text: String, saturation: CGFloat, brightness: CGFloat) -> UIColor{
    var hash = 0
    let colorConstant = 131
    let maxSafeValue = Int.max / colorConstant
    for char in text.unicodeScalars{
        if hash > maxSafeValue {
            hash = hash / colorConstant
        }
        hash = Int(char.value) + ((hash << 5) - hash)
    }
    let finalHash = abs(hash) % (256*256*256);
    let hue = ((CGFloat(finalHash) / 255.0) + 0.25).truncatingRemainder(dividingBy: 1)
    let color = UIColor(
        hue:hue,
        saturation: saturation,
        brightness: brightness,
        alpha: 1.0)
    return color
}

private func generateAbbreviationForText(_ text: String) -> String {
    let separated = text.uppercased().split(separator: " ").prefix(2)
    return separated.reduce("") {
        if let initial = $1.first {
            return $0 + String(initial)
        } else {
            return $0
        }
    }
}

private func largestSystemFontSize(text: String, paragraphStyle: NSParagraphStyle, rect: CGRect) -> UIFont {
    if text.isEmpty { return UIFont.preferredFont(forTextStyle: .largeTitle )}
    var fontSize: CGFloat = 1
    while
        rect.size.contains(size: (text as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .black), NSAttributedString.Key.paragraphStyle: paragraphStyle])) {
        fontSize = fontSize + 1
    }
    return UIFont.systemFont(ofSize: fontSize - 1, weight: .heavy)
}

extension Reactive where Base == AvatarView {
    var username: Binder<User> {
        return Binder(self.base) { view, user in
            view.user = user
        }
    }
}

extension CGSize {
    func contains(size: CGSize) -> Bool {
        return width >= size.width && height >= size.height
    }
}
