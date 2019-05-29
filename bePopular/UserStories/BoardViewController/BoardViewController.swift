//
//  ViewController.swift
//  CharityGod
//
//  Created by Bulat, Maksim on 17/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import Firebase

class BoardViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leagueButton: UIButton!
    @IBOutlet weak var coloredSeparatorView: UIView!
    @IBOutlet weak var donateButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewsCountLabel: UILabel!
    
    var league: LeagueProtocol?
    var themeColor = 0
    var boardRef: DatabaseReference!
    var boardMembers = [String]()
    var membersInfo = [String: NSDictionary]()

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "ic_logout")?.withRenderingMode(.alwaysTemplate)
        let refreshImage = UIImage(named: "ic_refresh")?.withRenderingMode(.alwaysTemplate)
        logoutButton.setImage(image, for: .normal)
        refreshButton.setImage(refreshImage, for: .normal)
        navigationController?.setNavigationBarHidden(true, animated: false)
        let colorHex = Int(league?.colorHEX ?? 0xfcc735)
        themeColor = colorHex
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let viewsCountRef = Database.database().reference().child("users").child(uid).child("public").child("views_count")
            viewsCountRef.observe(.value) { (snapshot) in
                if let viewsCount = snapshot.value as? Int? {
                    self.viewsCountLabel.text = "\(viewsCount ?? 0)"
                }

        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        league = LeaguesManager.league
        setupPersonalInfo()
        updateContent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        boardRef.removeAllObservers()
    }

    func updateContent() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        tableView.isHidden = true
        league = LeaguesManager.league
        themeColor = league?.colorHEX ?? 0xcd7f32
        setupUI()
        boardMembers = []
        self.tableView.reloadData()
        boardRef = Database.database().reference().child("boards").child(league?.name ?? "").child("members")
        boardRef.queryOrdered(byChild: "date").observe(.childAdded, with: { (snapshot) -> Void in
            let uid = snapshot.key
            self.boardMembers.insert(uid, at: 0)
            self.fetchUserInfo(uid: uid, completion: { (result) in
                self.membersInfo[uid] = result
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
                self.activityIndicator.isHidden = true
                self.tableView.isHidden = false
            })
        })
    }

    func setupUI() {
        let color = UIColor(hexRGB: themeColor)
        leagueButton.setTitle(league?.name.uppercased(), for: .normal)
        leagueButton.setTitleColor(color, for: .normal)
        coloredSeparatorView.backgroundColor = color
        donateButton.backgroundColor = color
        refreshButton.tintColor = color
        //logoutButton.tintColor = color
        donateButton.setTitle("Donate \(league?.price ?? "")$", for: .normal)
    }

    func setupPersonalInfo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            Alert.showErrorAlert(with: "No current user")
            return
        }

        fetchUserInfo(uid: uid) { (userInfoDict) in
            let firstName = userInfoDict.value(forKey: "first_name") as? String
            let lastName = userInfoDict.value(forKey: "last_name") as? String
            self.nameLabel.text = "\(firstName ?? "") \(lastName ?? "")"
            if let imageURLString = userInfoDict.value(forKey: "logo_image_url") as? String, let url = URL(string: imageURLString) {
                let image = ImageCache.shared.image(for: url, completion: {
                    self.setupPersonalInfo()
                })
                self.profileImageView.image = image ?? UIImage(named: "ic_photo")
            }
        }
    }

    func fetchUserInfo(uid: String, completion: @escaping (_ data: NSDictionary) -> Void) {
        DatabaseManager.shared.fetchUserInfo(uid: uid) { (result) in
            guard let userInfoDict = result?.value(forKey: "private") as? NSDictionary else {
                Alert.showErrorAlert(with: "No user information found")
                return
            }
            completion(userInfoDict)
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            let viewController = LoginViewController.storyboardInstance()
            let navigationController = UINavigationController(rootViewController: viewController)
            UIApplication.shared.keyWindow?.rootViewController = navigationController
        } catch(let error) {
            Alert.showErrorAlert(with: error.localizedDescription)
        }
    }

    @IBAction func onRefreshButton(_ sender: Any) {
        updateContent()
    }
    @IBAction func onProfileButton(_ sender: Any) {
        guard let viewController = ProfileViewController.storyboardInstance() as? ProfileViewController, let uid = Auth.auth().currentUser?.uid else {
            return
        }
        viewController.uid = uid
        navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func onLeagueButton(_ sender: Any) {
        boardRef.removeAllObservers()
        let viewController = LeaguesViewController.storyboardInstance()
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .formSheet
        self.addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    @IBAction func onLogoutButton(_ sender: Any) {
        let alert = Alert(title: "Logout", message: "Are you sure to logout?")
        alert.addAction(with: "Yes", alertStyle: .destructive) { (_) in
            self.logout()
        }
        alert.addAction(with: "No", alertStyle: .default)
        alert.present()
    }

    @IBAction func onPayButton(_ sender: Any) {
        DatabaseManager.shared.saveScore()
    }

}

extension BoardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boardMembers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? BoardTableViewCell else {
            return UITableViewCell()
        }
        let firstName = membersInfo[boardMembers[indexPath.row]]?.value(forKey: "first_name") as? String ?? ""
        let lastName = membersInfo[boardMembers[indexPath.row]]?.value(forKey: "last_name") as? String ?? ""
        cell.nameLabel.text = "\(firstName) \(lastName)"
        cell.positionLabel.text = "\(indexPath.row + 1)"
        cell.positionLabel.textColor = UIColor(hexRGB: themeColor)
        cell.separatedView.backgroundColor = UIColor(hexRGB: themeColor)
        if let urlString = membersInfo[boardMembers[indexPath.row]]?.value(forKey: "logo_image_url") as? String,
            let url = URL(string: urlString) {
            let image = ImageCache.shared.image(for: url) {
                self.tableView.reloadData()
            }
            cell.photoImageView.image = image ?? UIImage(named: "ic_photo")
        } else {
            cell.photoImageView.image = UIImage(named: "ic_photo")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewController = ProfileViewController.storyboardInstance() as? ProfileViewController else {
            return
        }
        viewController.uid = boardMembers[indexPath.row]
        navigationController?.pushViewController(viewController, animated: true)
    }
}

