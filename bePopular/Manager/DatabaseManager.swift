//
//  DatabaseManager.swift
//  bePopular
//
//  Created by Bulat, Maksim on 18/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import Foundation
import Firebase

class DatabaseManager: NSObject {

    static let shared = DatabaseManager()

    var ref: DatabaseReference!

    private override init() {
        super.init()
        ref = Database.database().reference()
    }

    func updateUser(uid: String, userData: UserInfo, completion: @escaping () -> Void) {
        guard let data = userData.dictionary else {
            assertionFailure()
            return
        }
        ref.child("users").child(uid).child("private").setValue(data) { (error, _) in
            if let error = error {
                Alert.showErrorAlert(with: error.localizedDescription)
                return
            }
            completion()
        }
    }

    func fetchUserInfo(uid: String, completion: @escaping (_ data: NSDictionary?) -> Void) {
        ref.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            completion(value)
        }) { (error) in
            Alert.showErrorAlert(with: error.localizedDescription)
        }
    }

    func saveScore() {
        let urlString = "https://us-central1-bepopular-7182d.cloudfunctions.net/helloContent"
        guard let uid = Auth.auth().currentUser?.uid, let url = URL(string: urlString) else {
            Alert.showErrorAlert(with: "No current user")
            return
        }
        let league = LeaguesManager.league?.name ??  ""
        let postData = SaveScore(uid: uid, league: league)
        guard let jsonData = try? JSONEncoder().encode(postData) else {
            assertionFailure()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            if let error = responseError {
                Alert.showErrorAlert(with: error.localizedDescription)
                return
            }
        }
        task.resume()

    }

    func updateViewsCounter(uid: String) {
        guard let selfUid = Auth.auth().currentUser?.uid else {
            return
        }
        let viewsCountRef = ref.child("users").child(uid).child("public").child("views_count")
        let viewsRef = ref.child("users").child(uid).child("public").child("views")
        if selfUid != uid {
            viewsRef.observeSingleEvent(of: .value) { (snapshot) in
                let views = snapshot.value as? [String?: Any?]
                if  views?.keys.contains(selfUid) == false || views == nil {
                    viewsCountRef.observeSingleEvent(of: .value) { (snapshot) in
                        if let count = snapshot.value as? Int {
                            viewsCountRef.setValue(count + 1)
                        } else {
                            viewsCountRef.setValue(1)
                        }
                    }
                    viewsRef.child(selfUid).setValue(Date().description)
                }
            }
        }
    }

}
