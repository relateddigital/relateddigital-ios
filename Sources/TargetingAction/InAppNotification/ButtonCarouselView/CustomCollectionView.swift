//
//  CustomCollectionView.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 12.06.2023.
//

import Foundation
import UIKit

class CustomCollectionView : UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButtonText: UILabel!
    @IBOutlet weak var closeButtonView: UIView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    public override func layoutSubviews() {
        super.layoutSubviews()
        setData()
    }
    
    func setData() {
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ButtonCarouselCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self

    }
    
}



extension CustomCollectionView : UICollectionViewDelegate, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonCarouselCollectionViewCell", for: indexPath)
        cell.contentMode = .center
        cell.backgroundColor = .clear
        let cellTemp: ButtonCarouselCollectionViewCell = UIView.fromNib()
        cellTemp.setData()
        cell.addSubview(cellTemp)
        cellTemp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cellTemp.topAnchor.constraint(equalTo: cell.topAnchor, constant: 0),
                                     cellTemp.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 0),
                                     cellTemp.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: 0),
                                     cellTemp.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: 0)])

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }
    
    
}
