//
//  League.swift
//  bePopular
//
//  Created by Bulat, Maksim on 20/05/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import Foundation

struct League: LeagueProtocol {
    var name: String
    var price: String
    var colorHEX: Int
}

protocol LeagueProtocol: Codable {
    var name: String { get }
    var price: String { get }
    var colorHEX: Int { get }
}

