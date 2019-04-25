import UIKit

class Alert: NSObject {
    private let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)

    convenience init(title: String = "",
                     message: String = "") {
        self.init()
        alert.title = title
        alert.message = message
    }

    func present() {
        let window = UIApplication.shared.keyWindow
        guard let viewController = window?.rootViewController else {
            assertionFailure("Oops, There is no rootViewController")
            return
        }
        viewController.present(alert, animated: true, completion: nil)
    }

    func addAction(with buttonTitle: String,
                   alertStyle: UIAlertAction.Style = .default,
                   handler: ((UIAlertAction) -> Void)? = nil) {
        alert.addAction(UIAlertAction(title: buttonTitle,
                                      style: alertStyle,
                                      handler: handler))
    }

    static func showErrorAlert(with message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        let window = UIApplication.shared.keyWindow
        guard let viewController = window?.rootViewController else {
            return
        }
        viewController.present(alert, animated: true, completion: nil)
    }
}
