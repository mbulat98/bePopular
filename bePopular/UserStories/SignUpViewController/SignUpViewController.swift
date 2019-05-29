//
//  SignUpViewController.swift
//  bePopular
//
//  Created by Bulat, Maksim on 19/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import GoogleSignIn
import FacebookLogin
import FacebookCore
import Firebase

class SignUpViewController: ScrollContentViewController {

    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var facebookLoginButtonView: UIView!
    @IBOutlet weak var contentScrollView: TappableScrollView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override var scrollView: TappableScrollView {
        return contentScrollView
    }

    let activityIndicator = ActivityIndicatorView()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self

        let facebookLoginButton = LoginButton(readPermissions: [.publicProfile, .email, .userAboutMe])
        facebookLoginButton.delegate = self
        facebookLoginButton.frame = CGRect(x: 0, y: 3, width: facebookLoginButtonView.frame.width, height: facebookLoginButtonView.frame.height + 1)
        facebookLoginButtonView.addSubview(facebookLoginButton)
        useCustomNavigationBar(backgroundColor: view.backgroundColor, tintColor: .gold)
        title = "Sign Up"
    }

    @IBAction func onCreateAccount(_ sender: Any) {
        guard let firstName = firstNameTextField.text else {
            Alert.showErrorAlert(with: "First name cannot be blank")
            return
        }
        guard let lastName = lastNameTextField.text else {
            Alert.showErrorAlert(with: "Last name cannot be blank")
            return
        }
        guard let email = emailTextField.text else {
            Alert.showErrorAlert(with: "Email cannot be blank")
            return
        }
        guard let password = passwordTextField.text else {
            Alert.showErrorAlert(with: "Password cannot be blank")
            return
        }
        activityIndicator.startAnimating()
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                Alert.showErrorAlert(with: error.localizedDescription)
                self.activityIndicator.stopAnimating()
                return
            }
            var userInfo = UserInfo()
            userInfo.firstName = firstName
            userInfo.lastName = lastName
            userInfo.email = email
            guard let uid = result?.user.uid else {
                assertionFailure()
                return
            }
            DatabaseManager.shared.updateUser(uid: uid, userData: userInfo) { () in
                self.openBoardViewController()
                self.activityIndicator.stopAnimating()
            }
        }
    }
    private func openBoardViewController() {
        let viewController = BoardViewController.storyboardInstance()
        let navigationController = UINavigationController(rootViewController: viewController)
        UIApplication.shared.keyWindow?.rootViewController = navigationController
    }
}

extension SignUpViewController: LoginButtonDelegate {
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
        if let userID = response.dictionaryValue?["id"] as? Int {
            userInfo.logoImageURL = "http://graph.facebook.com/\(userID)/picture?width=120&height=120"

        }
        userInfo.email = response.dictionaryValue?["email"] as? String
        DatabaseManager.shared.updateUser(uid: uid, userData: userInfo) { () in
            self.openBoardViewController()
            self.activityIndicator.stopAnimating()
            LoginManager().logOut()
        }
    }
}

extension SignUpViewController: GIDSignInUIDelegate, GIDSignInDelegate {
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
            DatabaseManager.shared.updateUser(uid: uid, userData: userInfo) { () in
                self.openBoardViewController()
                activityIndicator.stopAnimating()
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        try? Auth.auth().signOut()
    }
}
