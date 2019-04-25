import Foundation
import UIKit

extension UIViewController {
    static func storyboardInstance() -> UIViewController {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: Bundle.main)
        let viewController = storyboard.instantiateViewController(withIdentifier: String(describing: self))

        return viewController
    }

    func useCustomBackNavigationButton(color: UIColor = .black) {
        let backButton = UIBarButtonItem(image: UIImage(named: "ic_back"),
                                         style: .plain,
                                         target: navigationController,
                                         action: #selector(UINavigationController.popViewController(animated:)))
        navigationController?.navigationBar.tintColor = color
        navigationItem.leftBarButtonItem = backButton
    }
}
