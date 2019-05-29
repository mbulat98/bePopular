//
//  LeaguesManager.swift
//  bePopular
//
//  Created by Bulat, Maksim on 20/05/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import Foundation

class LeaguesManager {
    static var league: League?

    class func setLeague(league: League?) {
        if let league = league {
            self.league = league
        } else {
            restoreLeague()
        }
    }

    class func saveLeague() {
        if let league = self.league {
            do {
                let encodedData = try JSONEncoder().encode(league)
                UserDefaults.standard.set(encodedData, forKey: "saved_league")
            } catch {
                Alert.showErrorAlert(with: error.localizedDescription)
            }
        }
    }

    private class func restoreLeague() {
        if let leagueData = UserDefaults.standard.value(forKey: "saved_league") as? Data {
            do {
                let league = try JSONDecoder().decode(League.self, from: leagueData)
                self.league = league
            } catch {
                Alert.showErrorAlert(with: error.localizedDescription)
            }
        } else {
            self.league = League(name: "bronze", price: "0.99", colorHEX: 0xcd7f32)
        }
    }
}
