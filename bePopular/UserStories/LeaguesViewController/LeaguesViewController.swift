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
    private var leagues = [League]()
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
            var colorHEX = 0x000
            var price = ""
            if let dict = snapshot.value as? [String: Any] {
                if let colorHex = UInt(dict["color"] as! String, radix: 16) {
                    colorHEX = Int(colorHex)
                }
                if let tempPrice = dict["price"] as? String {
                    price = tempPrice
                }
            }
            let league = League(name: leagueTitle, price: price, colorHEX: colorHEX)
            self.leagues.append(league)
            activityIndicator.stopAnimating()
            self.tableView.reloadData()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        leaguesRef.removeAllObservers()
    }
    
    @IBAction func onTap(_ sender: UIGestureRecognizer) {
        let point = sender.location(in: tableView)
        if tableView.indexPathForRow(at: point) == nil {
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
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
        let league = leagues[indexPath.row]
        let title = league.name
        cell.leagueButton.setTitle(title.uppercased(), for: .normal)
        let color = UIColor(hexRGB: league.colorHEX)
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
        let league = leagues[sender.tag]
        LeaguesManager.setLeague(league: league)
        (self.parent as! BoardViewController).updateContent()
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
}
