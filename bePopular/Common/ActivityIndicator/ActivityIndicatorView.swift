import UIKit

class ActivityIndicatorView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private let activityTag = 127

    init() {
        super.init(frame: UIScreen.main.bounds)
        setupTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTheme()
    }

    func  setupTheme() {
        Bundle.main.loadNibNamed("ActivityIndicatorView", owner: self, options: nil)
        activityIndicator.startAnimating()
        addSubview(contentView)
        self.frame = UIScreen.main.bounds
        contentView.frame = UIScreen.main.bounds
    }

    func startAnimating() {
        DispatchQueue.main.async {
            let parentView = UIApplication.shared.keyWindow
            guard  parentView?.viewWithTag(self.activityTag) == nil else {return}
            self.tag = self.activityTag
            parentView?.addSubview(self)
        }
    }

    func stopAnimating() {
        DispatchQueue.main.async {
            let parentView = UIApplication.shared.keyWindow
            guard  parentView?.viewWithTag(self.activityTag) != nil else {return}
            parentView?.viewWithTag(self.activityTag)?.removeFromSuperview()
        }
    }
}
