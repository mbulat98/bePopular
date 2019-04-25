//
//  UserInfo.swift
//  bePopular
//
//  Created by Bulat, Maksim on 18/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import Foundation

struct UserInfo: Encodable {
    var firstName: String?
    var lastName: String?
    var logoImageURL: String?
    var email: String?
    var instagramLink: String?
    var facebookLink: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case logoImageURL = "logo_image_url"
        case email = "user_email"
        case instagramLink = "insta_link"
        case facebookLink = "facebook_link"
    }
}
