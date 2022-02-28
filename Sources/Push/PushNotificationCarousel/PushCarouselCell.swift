//
//  PushCarouselCell.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 14.02.2022.
//

import UIKit

class PushCarouselCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var content: UILabel!

    func setupCell(imageUrl: String?, title: String?, content: String?) {
        self.title.text = title
        self.content.text = content
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else { return }
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) in
            if error == nil {
                guard let unwrappedData = data, let image = UIImage(data: unwrappedData) else { return }
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        })
        task.resume()
    }
    
}
