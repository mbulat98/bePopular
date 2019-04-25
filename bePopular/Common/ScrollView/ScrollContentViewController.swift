import Foundation
import UIKit

protocol TappableScrollViewDelegate: class {
    func didReceiveTap(touches: Set<UITouch>)
}

class ScrollContentViewController: UIViewController {

    var scrollView: UIScrollView? {
        return nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let scrollView = scrollView as? TappableScrollView {
             scrollView.tappableScrollViewDelegate = self
        }

        scrollView?.keyboardDismissMode = .interactive

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowOrHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
         NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShowOrHide(notification: Notification) {
        guard let scrollView = scrollView,
              let userInfo = notification.userInfo,
              let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey],
              let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey],
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] else {
                return
        }
        let endRect = view.convert((endValue as AnyObject).cgRectValue, from: view.window)
        var tabbarHeight:CGFloat = 0
        if notification.name == UIResponder.keyboardWillHideNotification && tabBarController?.tabBar.isHidden == false {
            tabbarHeight = tabBarController?.tabBar.bounds.height ?? 0
        }
        let keyboardOverlap = scrollView.frame.maxY + tabbarHeight - endRect.origin.y

        scrollView.contentInset.bottom = keyboardOverlap
        scrollView.scrollIndicatorInsets.bottom = keyboardOverlap

        scrollView.keyboardDismissMode = .interactive

        let duration = (durationValue as AnyObject).doubleValue
        let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
        UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension ScrollContentViewController: TappableScrollViewDelegate {

    func didReceiveTap(touches: Set<UITouch>) {
        view.endEditing(true)
        if presentedViewController  == self.parent {
            if touches.first?.view == scrollView {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}
