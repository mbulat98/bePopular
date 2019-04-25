//
//  ImageCache.swift
//  bePopular
//
//  Created by Bulat, Maksim on 25/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit

class ImageCache {

    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func downloadImage(from url: URL, completion: @escaping () -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
            if let localURL = localURL, let data = try? Data(contentsOf: localURL) {
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        self.cache.setObject(image, forKey: url.absoluteString as NSString)
                        completion()
                    }
                }
            }
        }
        task.resume()
    }

    func image(for url: URL, completion: @escaping () -> Void) -> UIImage? {
        if let image = cache.object(forKey: url.absoluteString as NSString) {
            return image
        } else {
            downloadImage(from: url, completion: completion)
            return nil
        }
    }
}
