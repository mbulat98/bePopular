//
//  LoginViewController.swift
//  CharityGod
//
//  Created by Bulat, Maksim on 17/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FacebookLogin
import FacebookCore

class LoginViewController: ScrollContentViewController {

    @IBOutlet weak var contentScrollView: TappableScrollView!
    @IBOutlet weak var loginFormView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var googleLoginButton: GIDSignInButton!
    @IBOutlet weak var facebookLoginButtonView: LoginButton!
    
    override var scrollView: TappableScrollView? {
        return contentScrollView
    }

    let cornerRadiusValue: CGFloat = 5
    let borderWidthValue: CGFloat = 2
    let leftPadding: CGFloat = 10
    let borderColor = UIColor.white.cgColor
    let placeholderColor = UIColor.lightGray
    let activityIndicator = ActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self

        let facebookLoginButton = LoginButton(readPermissions: [.publicProfile, .email, .userAboutMe])
        facebookLoginButton.delegate = self
        facebookLoginButton.frame = CGRect(x: 0, y: 3, width: facebookLoginButtonView.frame.width + 20, height: facebookLoginButtonView.frame.height + 1)
        facebookLoginButtonView.addSubview(facebookLoginButton)
    }

    @IBAction func onCreateAccount(_ sender: Any) {
        let viewController = SignUpViewController.storyboardInstance()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func onLoginButton(_ sender: Any) {
        activityIndicator.startAnimating()
        Auth.auth().signIn(withEmail: emailTextField.text ?? "", password: passwordTextField.text ?? "") { (result, error) in
            if let error = error {
                Alert.showErrorAlert(with: error.localizedDescription)
                return
            }
            self.openBoardViewController()
        }
    }

    func setupUI() {
        let attributes = [NSAttributedString.Key.foregroundColor: placeholderColor]
        emailTextField.layer.borderColor = borderColor
        emailTextField.layer.borderWidth = borderWidthValue
        emailTextField.layer.cornerRadius = cornerRadiusValue
        emailTextField.layer.masksToBounds = true
        emailTextField.setLeftPaddingPoints(leftPadding)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "example@gmail.com", attributes: attributes)
        passwordTextField.layer.borderColor = borderColor
        passwordTextField.layer.borderWidth = borderWidthValue
        passwordTextField.layer.cornerRadius = cornerRadiusValue
        passwordTextField.layer.masksToBounds = true
        passwordTextField.setLeftPaddingPoints(leftPadding)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "password", attributes: attributes)
        loginButton.layer.borderColor = borderColor
        loginButton.layer.borderWidth = borderWidthValue
        loginButton.layer.cornerRadius = cornerRadiusValue
        loginButton.layer.masksToBounds = true
        loginFormView.layer.cornerRadius = cornerRadiusValue
        loginFormView.layer.masksToBounds = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func openBoardViewController() {
        let viewController = BoardViewController.storyboardInstance()
        let navigationController = UINavigationController(rootViewController: viewController)
        UIApplication.shared.keyWindow?.rootViewController = navigationController
    }

}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        activityIndicator.startAnimating()
        switch result {
        case .failed(let error):
            Alert.showErrorAlert(with: error.localizedDescription)
            return
        case .success(_, _, let token):
            loginWithFacebook(token: token)
        default:
            activityIndicator.stopAnimating()
            return
        }

    }

    func loginButtonDidLogOut(_ loginButton: LoginButton) {
    }

    func loginWithFacebook(token: AccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                Alert.showErrorAlert(with: error.localizedDescription)
                return
            }
            guard let uid = authResult?.user.uid else {
                assertionFailure()
                return
            }
            let connection = GraphRequestConnection()
            connection.add(GraphRequest(graphPath: "/me")) { _, result in
                switch result {
                case .success(let response):
                    self.saveFacebookUserInfo(response: response, uid: uid)
                case .failed(let error):
                    Alert.showErrorAlert(with: error.localizedDescription)
                    self.activityIndicator.stopAnimating()
                }
            }
            connection.start()

        }
    }

    func saveFacebookUserInfo(response: GraphRequest.Response, uid: String) {
        let name = response.dictionaryValue?["name"] as? String
        var userInfo = UserInfo()
        userInfo.firstName = String(name?.split(separator: " ")[0] ?? "")
        userInfo.lastName = String(name?.split(separator: " ")[1] ?? "")
        if let userID = response.dictionaryValue?["id"] as? String {
            userInfo.logoImageURL = "http://graph.facebook.com/\(userID)/picture?width=120&height=120"

        }
        userInfo.email = response.dictionaryValue?["email"] as? String
        DatabaseManager.shared.createUser(uid: uid, userData: userInfo) { () in
            self.openBoardViewController()
            self.activityIndicator.stopAnimating()
            LoginManager().logOut()
        }
    }
}

extension LoginViewController: GIDSignInUIDelegate, GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        let activityIndicator = ActivityIndicatorView()
        activityIndicator.startAnimating()
        if let error = error {
            activityIndicator.stopAnimating()
            Alert.showErrorAlert(with: error.localizedDescription)
            return
        }

        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                activityIndicator.stopAnimating()
                Alert.showErrorAlert(with: error.localizedDescription)
                return
            }
            var userInfo = UserInfo()
            userInfo.firstName = user.profile.givenName
            userInfo.lastName = user.profile.familyName
            userInfo.email = user.profile.email
            if user.profile.hasImage {
                userInfo.logoImageURL = user.profile.imageURL(withDimension: 120)?.absoluteString
            }
            guard let uid = authResult?.user.uid else {
                assertionFailure()
                return
            }
            DatabaseManager.shared.createUser(uid: uid, userData: userInfo) { () in
                self.openBoardViewController()
                activityIndicator.stopAnimating()
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        try? Auth.auth().signOut()
    }
}

