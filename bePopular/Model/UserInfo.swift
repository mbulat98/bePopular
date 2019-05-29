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
    var about: String?
    var instagramLink: String?
    var facebookLink: String?
    var linkedinLink: String?
    var googleLink: String?
    var twitterLink: String?
    var vkLink: String?

//    init(firstName: String?, lastName: String?, logoImageURL: String?, email: String?) {
//        self.firstName = firstName
//        self.lastName = lastName
//        self.logoImageURL = logoImageURL
//        self.email = email
//        instagramLink = nil
//        facebookLink = nil
//    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case about = "user_about"
        case logoImageURL = "logo_image_url"
        case email = "user_email"
        case instagramLink = "insta_link"
        case facebookLink = "facebook_link"
        case googleLink = "google_link"
        case linkedinLink = "linkedin_linl"
        case twitterLink = "twitter_link"
        case vkLink = "vk_link"
    }
}
