import Foundation
import UIKit

extension UIColor {
    static let gold = UIColor(hexRGB: 0xFCC735)
    convenience init(hexRGB: Int) {
        let red = CGFloat((hexRGB >> 16) & 0xFF) / 255
        let green = CGFloat((hexRGB >> 8) & 0xFF) / 255
        let blue = CGFloat(hexRGB & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    convenience init(hexARGB: Int) {
        let alpha = CGFloat((hexARGB >> 24) & 0xFF)
        let red = CGFloat((hexARGB >> 16) & 0xFF) / 255
        let green = CGFloat((hexARGB >> 8) & 0xFF) / 255
        let blue = CGFloat(hexARGB & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: alpha / 100)
    }
}
