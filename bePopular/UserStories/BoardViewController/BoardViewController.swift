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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leagueButton: UIButton!
    @IBOutlet weak var coloredSeparatorView: UIView!
    @IBOutlet weak var donateButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    var league = ""
    var themeColor = 0
    var boardRef: DatabaseReference!
    var boardMembers = [String]()
    var membersInfo = [String: NSDictionary]()

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupPersonalInfo()
        league = (UserDefaults.standard.value(forKey: UserDefaultKeys.league.rawValue) as? String) ?? "gold"
        let colorString = (UserDefaults.standard.value(forKey: UserDefaultKeys.appColor.rawValue) as? String) ?? "FCC735"
        let colorHex = Int(UInt(colorString, radix: 16) ?? 0xfcc735)
        themeColor = colorHex
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        boardRef.removeAllObservers()
    }

    func updateContent() {
        league = (UserDefaults.standard.value(forKey: UserDefaultKeys.league.rawValue) as? String) ?? "gold"
        themeColor = (UserDefaults.standard.value(forKey: UserDefaultKeys.appColor.rawValue) as? Int) ?? 0xFCC735
        setupUI()
        boardMembers = []
        self.tableView.reloadData()
        boardRef = Database.database().reference().child("boards").child(league).child("members")
        boardRef.queryOrdered(byChild: "date").observe(.childAdded, with: { (snapshot) -> Void in
            let uid = snapshot.key
            self.boardMembers.insert(uid, at: 0)
            self.fetchUserInfo(uid: uid, completion: { (result) in
                self.membersInfo[uid] = result
                self.tableView.reloadData()
            })
        })
        boardRef.observe(.childChanged, with: { (snapshot) -> Void in
            let uid = snapshot.key
            if let index = self.boardMembers.firstIndex(of: uid) {
                self.boardMembers.remove(at: index)
                self.boardMembers.insert(uid, at: 0)
                self.tableView.reloadData()
            }
        })
        boardRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let uid = snapshot.key
            if let index = self.boardMembers.firstIndex(of: uid) {
                self.boardMembers.remove(at: index)
                self.tableView.reloadData()
            }
        })
    }

    func setupUI() {
        let color = UIColor(hexRGB: themeColor)
        leagueButton.setTitle(league.uppercased(), for: .normal)
        leagueButton.setTitleColor(color, for: .normal)
        coloredSeparatorView.backgroundColor = color
        donateButton.backgroundColor = color
        logoutButton.tintColor = color
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
                let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
                    if let localURL = localURL, let data = try? Data(contentsOf: localURL) {
                        DispatchQueue.main.async {
                            self.profileImageView.image = UIImage(data: data)
                        }
                    }
                }
                task.resume()
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

    @IBAction func onLeagueButton(_ sender: Any) {
        boardRef.removeAllObservers()
        let viewController = LeaguesViewController.storyboardInstance()
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .formSheet
        self.addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
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
        cell.photoImageView.image = UIImage(named: "ic_photo")
        return cell
    }
}

