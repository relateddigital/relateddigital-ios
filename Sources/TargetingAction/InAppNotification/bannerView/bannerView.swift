//
//  bannerView.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 1.05.2022.
//

import UIKit

class bannerView: UIView {

    @IBOutlet weak var currentPageView: UIView!
    @IBOutlet weak var currentPageLabel: UILabel!
    @IBOutlet weak var pageControlView: UIPageControl!
    @IBOutlet weak var pageControlHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
