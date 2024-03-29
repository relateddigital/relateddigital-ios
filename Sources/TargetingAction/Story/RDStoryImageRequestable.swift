//
//  RDStoryImageRequestable.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation
import UIKit

public enum RDStoryImageResult<V, E> {
    case success(V)
    case failure(E)
}

public typealias ImageResponse = (RDStoryImageResult<UIImage, Error>) -> Void

protocol RDStoryImageRequestable {
    func setImage(urlString: String, placeHolderImage: UIImage?, completionBlock: ImageResponse?)
}

extension RDStoryImageRequestable where Self: UIImageView {

    func setImage(urlString: String, placeHolderImage: UIImage? = nil, completionBlock: ImageResponse?) {

        self.image = (placeHolderImage != nil) ? placeHolderImage! : nil
        self.showActivityIndicator()

        if let cachedImage = RDStoryImageCache.shared.object(forKey: urlString as AnyObject) as? UIImage {
            self.hideActivityIndicator()
            DispatchQueue.main.async {
                self.image = cachedImage
            }
            guard let completion = completionBlock else { return }
            return completion(.success(cachedImage))
        } else {
            RDStoryImageURLSession.default.downloadImage(using: urlString) { [weak self] (response) in
                guard let strongSelf = self else { return }
                strongSelf.hideActivityIndicator()
                switch response {
                case .success(let image):
                    DispatchQueue.main.async {
                        strongSelf.image = image
                    }
                    guard let completion = completionBlock else { return }
                    return completion(.success(image))
                case .failure(let error):
                    guard let completion = completionBlock else { return }
                    return completion(.failure(error))
                }
            }
        }
    }
}

enum ImageStyle: Int {
    case squared, rounded
}

public enum RelatedDigitalStoryImageRequestResult<V, E> {
    case success(V)
    case failure(E)
}

typealias SetImageRequester = (RelatedDigitalStoryImageRequestResult<Bool, Error>) -> Void

extension UIImageView: RDStoryImageRequestable {
    func setImage(url: String,
                  style: ImageStyle = .rounded,
                  completion: SetImageRequester? = nil) {
        image = nil

        // The following stmts are in SEQUENCE. before changing the order think twice :P
        isActivityEnabled = true
        layer.masksToBounds = false
        if style == .rounded {
            layer.cornerRadius = frame.height/2
            activityStyle = .white
        } else if style == .squared {
            layer.cornerRadius = 0
            activityStyle = .whiteLarge
        }

        clipsToBounds = true
        setImage(urlString: url) { (response) in
            if let completion = completion {
                switch response {
                case .success:
                    completion(RelatedDigitalStoryImageRequestResult.success(true))
                case .failure(let error):
                    completion(RelatedDigitalStoryImageRequestResult.failure(error))
                }
            }
        }
    }
}
