import Foundation
import UIKit

class TappableScrollView: UIScrollView {

    weak var tappableScrollViewDelegate: TappableScrollViewDelegate?

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tappableScrollViewDelegate?.didReceiveTap(touches: touches)
    }
}
