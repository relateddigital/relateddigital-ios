//
//  RDStoryImageURLSession.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

class RDStoryImageURLSession: URLSession {
    static let `default` = RDStoryImageURLSession()
    private(set) var dataTasks: [URLSessionDataTask] = []
}
extension RDStoryImageURLSession {
    func cancelAllPendingTasks() {
        dataTasks.forEach({
            if $0.state != .completed {
                $0.cancel()
            }
        })
    }

    func downloadImage(using urlString: String, completionBlock: @escaping ImageResponse) {
        guard let url = URL(string: urlString) else {
            return completionBlock(.failure(RDStoryImageError.invalidImageURL))
        }
        dataTasks.append(RDStoryImageURLSession.shared.dataTask(with: url, completionHandler: {(data, _, error) in
            if let result = data, error == nil, let imageToCache = UIImage(data: result) {
                RDStoryImageCache.shared.setObject(imageToCache, forKey: url.absoluteString as AnyObject)
                completionBlock(.success(imageToCache))
            } else {
                return completionBlock(.failure(error ?? RDStoryImageError.downloadError))
            }
        }))
        dataTasks.last?.resume()
    }
}
