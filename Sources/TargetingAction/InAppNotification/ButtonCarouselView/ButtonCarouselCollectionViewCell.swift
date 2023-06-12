//
//  ButtonCarouselCollectionViewCell.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 12.06.2023.
//

import UIKit

class ButtonCarouselCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var pageControlView: UIPageControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var buttonTextLabel: UILabel!
    @IBOutlet weak var buttonView: UIView!
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func setData() {
        
    }
}
