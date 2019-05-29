//
//  ProfileViewController.swift
//  bePopular
//
//  Created by Bulat, Maksim on 20/05/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class ProfileViewController: ScrollContentViewController {
    @IBOutlet weak var contentScrollView: TappableScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var googleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var twitterBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var vkBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkedinBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var instagramBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var facebookBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var vkView: UIView!
    @IBOutlet weak var linkedinView: UIView!
    @IBOutlet weak var instagramView: UIView!
    @IBOutlet weak var googleView: UIView!
    @IBOutlet weak var facebookView: UIView!
    @IBOutlet weak var twitterView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var facebookTextView: UITextView!
    @IBOutlet weak var googleTextView: UITextView!
    @IBOutlet weak var twitterTextView: UITextView!
    @IBOutlet weak var instagramTextView: UITextView!
    @IBOutlet weak var linkedinTextView: UITextView!
    @IBOutlet weak var vkTextView: UITextView!
    @IBOutlet weak var aboutTextView: UITextView!
    @IBOutlet weak var nameTextView: UITextView!
    @IBOutlet weak var imageLoadingView: UIActivityIndicatorView!
    var saveButton: UIButton!

    override var scrollView: TappableScrollView {
        return contentScrollView
    }

    let socialSpacing: CGFloat = 5
    
    var uid: String?
    private var userImageLink: String?
    private var photoForUpload: UIImage?
    var isEditable:Bool = true {
        willSet {
            facebookTextView.isEditable = newValue
            googleTextView.isEditable = newValue
            twitterTextView.isEditable = newValue
            instagramTextView.isEditable = newValue
            linkedinTextView.isEditable = newValue
            vkTextView.isEditable = newValue
            aboutTextView.isEditable = newValue
            nameTextView.isEditable = newValue
            //saveButton.isHidden = !newValue
            scrollViewBottomConstraint.constant = newValue ? 20 : -70
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        useCustomNavigationBar(backgroundColor: view.backgroundColor, tintColor: .gold)
        createSaveButton()
        setupPersonalInfo()
        updateViewsCounter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardOpen), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @objc private func onKeyboardOpen() {
        self.saveButton.isHidden = false
    }

    private func createSaveButton() {
        saveButton = UIButton(type: .custom)
        saveButton.setTitle("   Save   ", for: .normal)
        saveButton.setTitleColor(.gold, for: .normal)
        saveButton.layer.cornerRadius = 5
        saveButton.layer.masksToBounds = true
        saveButton.layer.borderColor = UIColor.gold.cgColor
        saveButton.layer.borderWidth = 1
        saveButton.addTarget(self, action: #selector(onSaveButton(_:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        saveButton.isHidden = true
    }

    private func updateViewsCounter() {
        if let uid = uid {
            DatabaseManager.shared.updateViewsCounter(uid: uid)
        }
    }

    private func setupPersonalInfo() {
        guard let uid = uid else {
            Alert.showErrorAlert(with: "Something went wrong")
            return
        }
        let activityIndicator = ActivityIndicatorView()
        activityIndicator.startAnimating()
        isEditable = Auth.auth().currentUser?.uid == uid
        DatabaseManager.shared.fetchUserInfo(uid: uid) { (userInfo) in
            guard let data = userInfo?.value(forKey: "private") as? [String: Any] else {
                assertionFailure("No user information")
                return
            }
            let firstName = data["first_name"] as? String
            let lastName = data["last_name"] as? String
            self.nameTextView.text = "\(firstName ?? "") \(lastName ?? "")"
            self.aboutTextView.text = data["user_about"] as? String
            self.facebookTextView.text = data["facebook_link"] as? String
            self.hideTextViewIfNeeded(text: self.facebookTextView.text, view: self.facebookView, constraint: self.facebookBottomContraint)
            self.googleTextView.text = data["google_link"] as? String
            self.hideTextViewIfNeeded(text: self.googleTextView.text, view: self.googleView, constraint: self.googleBottomConstraint)
            self.twitterTextView.text = data["twitter_link"] as? String
            self.hideTextViewIfNeeded(text: self.twitterTextView.text, view: self.twitterView, constraint: self.twitterBottomConstraint)
            self.instagramTextView.text = data["instagram_link"] as? String
            self.hideTextViewIfNeeded(text: self.instagramTextView.text, view: self.instagramView, constraint: self.instagramBottomConstaint)
            self.linkedinTextView.text = data["linkedin_link"] as? String
            self.hideTextViewIfNeeded(text: self.linkedinTextView.text, view: self.linkedinView, constraint: self.linkedinBottomContraint)
            self.vkTextView.text = data["vk_link"] as? String
            self.hideTextViewIfNeeded(text: self.vkTextView.text, view: self.vkView, constraint: self.vkBottomConstraint)
            if let imageURLString = data["logo_image_url"] as? String, let url = URL(string: imageURLString) {
                self.userImageLink = imageURLString
                let image = ImageCache.shared.image(for: url, completion: {
                    self.setupPersonalInfo()
                })
                if let image = image {
                    self.avatarImageView.image = image
                    self.imageLoadingView.stopAnimating()
                }
            }
            activityIndicator.stopAnimating()
        }
    }

    private func hideTextViewIfNeeded(text: String?, view: UIView, constraint: NSLayoutConstraint) {
        if text?.isEmpty ?? true, isEditable == false {
            view.isHidden = true
            constraint.constant = -51
        }
    }

    private func uploadPhoto(image: UIImage, completion: @escaping (String) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("\(uid ?? "").jpg")
        if let data = image.pngData() {
            imageRef.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    Alert.showErrorAlert(with: error.localizedDescription)
                }
                imageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        Alert.showErrorAlert(with: error?.localizedDescription ?? "")
                        return
                    }
                    completion(downloadURL.absoluteString)
                }
            }
        }
    }

    @objc func onSaveButton(_ sender: Any) {
        guard let uid = uid else {
            assertionFailure("No uid")
            return
        }
        let activityView = ActivityIndicatorView()
        activityView.startAnimating()
        var userInfo = UserInfo()
        userInfo.firstName = nameTextView.text
        userInfo.about = aboutTextView.text
        userInfo.facebookLink = facebookTextView.text
        userInfo.googleLink = googleTextView.text
        userInfo.twitterLink = twitterTextView.text
        userInfo.instagramLink = instagramTextView.text
        userInfo.linkedinLink = linkedinTextView.text
        userInfo.vkLink = vkTextView.text
        userInfo.logoImageURL = userImageLink
        if let image = photoForUpload {
            uploadPhoto(image: image) { (urlString) in
                userInfo.logoImageURL = urlString
                DatabaseManager.shared.updateUser(uid: uid, userData: userInfo) {
                    self.view.endEditing(false)
                    self.saveButton.isHidden = true
//                    self.navigationController?.popViewController(animated: true)
                    activityView.stopAnimating()
                }
            }
        } else {
            DatabaseManager.shared.updateUser(uid: uid, userData: userInfo) {
                self.view.endEditing(false)
                self.saveButton.isHidden = true
                //self.navigationController?.popViewController(animated: true)
                activityView.stopAnimating()
            }
        }
    }

    @IBAction func onEdgeGesture(_ sender: UIScreenEdgePanGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onImageButton(_ sender: Any) {
        guard isEditable else {
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Choose from gallery", style: .default, handler: { _ in
            self.openPickerViewController(withCamera: false)
            self.saveButton.isHidden = false
        }))
        alert.addAction(UIAlertAction(title: "Take with camera", style: .default, handler: { _ in
            self.saveButton.isHidden = false
            self.openPickerViewController(withCamera: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(alert, animated: true)
    }

    func openPickerViewController(withCamera: Bool) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = withCamera ? .camera : .photoLibrary
        self.present(imagePicker, animated: true)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            Alert.showErrorAlert(with: "Cannot load image")
            return
        }
        self.avatarImageView.image = image
        photoForUpload = image
        picker.dismiss(animated: true)
    }
}
