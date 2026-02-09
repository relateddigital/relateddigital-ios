//
//  RDExtensions.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.04.2020.
//

import UIKit

/**
JSON convenient categories on NSString
*/
extension String {

    func contains(_ string: String, options: String.CompareOptions) -> Bool {
        let rng = (self as NSString).range(of: string, options: options)
        return rng.location != NSNotFound
    }

    func contains(_ string: String) -> Bool {
        return contains(string, options: [])
    }

    func urlDecode() -> String {
        return self.removingPercentEncoding ?? ""
    }

    func convertJsonStringToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }

    var isEmptyOrWhitespace: Bool {
        return self.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func getUrlWithoutExtension() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().absoluteString
    }

    func getUrlExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
    
    func removeWhitespace() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
}

extension Optional where Wrapped == String {

    var isNilOrWhiteSpace: Bool {
        return self?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
    }

}

extension Optional where Wrapped == [String] {
    mutating func mergeStringArray(_ newArray: [String]) {
        self = self ?? [String]()
        for newArrayElement in newArray {
            if !self!.contains(newArrayElement) {
                self!.append(newArrayElement)
            }
        }
    }
}

extension Int {
    var toFloat: CGFloat {
        return CGFloat(self)
    }
}


public let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    
    
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let newImage = UIImage(data: data) else {
                print("Failed to load image:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            DispatchQueue.main.async {
                self.image = newImage
            }
        }.resume()
    }
    
    
    func setImageWithImageSize(withUrl urlString : String) {
        if let url = URL(string: urlString) {
            self.image = nil

            // check cached image
            if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
                self.height(cachedImage.size.height)
                self.image = cachedImage
                return
            }
            // if not, download image from url
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }

                DispatchQueue.main.async {
                    if let image = UIImage.gif(data: data!) {
                        imageCache.setObject(image, forKey: urlString as NSString)
                        self.height(image.size.height)
                        self.image = image
                    }
                }

            }).resume()
        }
    }
    
    func setImage(withUrl urlString : String) {
        if let url = URL(string: urlString) {
            self.image = nil

            // check cached image
            if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
                self.image = cachedImage
                return
            }
            // if not, download image from url
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }

                DispatchQueue.main.async {
                    if let image = UIImage.gif(data: data!) {
                        imageCache.setObject(image, forKey: urlString as NSString)
                        self.image = image
                    }
                }

            }).resume()
        }
    }
    
    func setImage(withUrl urlString : URL?, completion: (() -> Void)? = nil) {
        if let url = urlString {
            self.image = nil

            // if not, download image from url
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }

                DispatchQueue.main.async {
                    if let image = UIImage.gif(data: data!) {
                        self.image = image
                        if self.superview is RDPopupDialogDefaultView {
                            let viewPop = self.superview as! RDPopupDialogDefaultView
                            viewPop.imageHeightConstraint?.constant = viewPop.imageView.pv_heightForImageView(isVideoExist: false)
                        } else if self.superview is RDNpsWithNumbersCollectionView {
                            let viewPop = self.superview as! RDNpsWithNumbersCollectionView
                            let height = viewPop.imageView.pv_heightForImageView(isVideoExist: false)
                            viewPop.imageHeightConstraint?.constant = height
                            self.layoutIfNeeded()
                        }
                        completion?()
                    }
                }

            }).resume()
        }
    }
}
