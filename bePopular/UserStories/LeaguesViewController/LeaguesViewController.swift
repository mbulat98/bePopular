//
//  LeaguesViewController.swift
//  bePopular
//
//  Created by Bulat, Maksim on 22/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import Firebase

class LeaguesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var leaguesRef: DatabaseReference!
    private var leagues = [String]()
    private var colors = [String: Int]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let activityIndicator = ActivityIndicatorView()
        activityIndicator.startAnimating()
        leaguesRef = Database.database().reference().child("leagues")
        leaguesRef.queryOrdered(byChild: "id").observe(.childAdded, with: { (snapshot) -> Void in
            let leagueTitle = snapshot.key
            self.leagues.append(leagueTitle)
            if let dict = snapshot.value as? [String: Any] {
                if let colorHex = UInt(dict["color"] as! String, radix: 16) {
                    self.colors[leagueTitle] = Int(colorHex)
                }
            }
            activityIndicator.stopAnimating()
            self.tableView.reloadData()
        })
//        leaguesRef.observe(.childChanged, with: { (snapshot) -> Void in
//            let leagueTitle = snapshot.key
//            if let index = self.leagues.firstIndex(of: leagueTitle) {
//                self.leagues.remove(at: index)
//                self.leagues.insert(leagueTitle, at: 0)
//                self.tableView.reloadData()
//                if let dict = snapshot.value as? [String: Any], let colorHex = dict["color"] as? Int {
//                    self.colors[leagueTitle] = colorHex
//                }
//            }
//        })
        leaguesRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let leagueTitle = snapshot.key
            if let index = self.leagues.firstIndex(of: leagueTitle) {
                self.leagues.remove(at: index)
                self.tableView.reloadData()
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        leaguesRef.removeAllObservers()
    }
    

}

extension LeaguesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leagues.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? LeaguesTableViewCell else {
            assertionFailure()
            return UITableViewCell()
        }
        let title = leagues[indexPath.row]
        cell.leagueButton.setTitle(title.uppercased(), for: .normal)
        let color = UIColor(hexRGB: colors[title] ?? 0xFFF)
        cell.leagueButton.setTitleColor(color, for: .normal)
        cell.leagueButton.layer.borderColor = color.cgColor
        cell.leagueButton.layer.borderWidth = 2
        cell.leagueButton.layer.cornerRadius = 50
        cell.leagueButton.layer.masksToBounds = true
        cell.leagueButton.tag = indexPath.row
        cell.leagueButton.addTarget(self, action: #selector(onLeague(sender:)), for: .touchUpInside)
        return cell
    }

    @objc func onLeague(sender: UIButton) {
        let title = leagues[sender.tag]
        UserDefaults.standard.set(title, forKey: UserDefaultKeys.league.rawValue)
        UserDefaults.standard.set(colors[title], forKey: UserDefaultKeys.appColor.rawValue)
        (self.parent as! BoardViewController).updateContent()
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
}
