//
//  ButtonCarouselView.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 12.06.2023.
//

import UIKit

public class ButtonCarouselView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var model: ButtonCarouselViewModel!
    var propertiesLocal : Properties?
    public var delegate:ButtonCarouselViewDelegate?

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        print("selam")
        setData()
        setListeners()
    }
    
    func setData() {
        imageView.setImage(withUrl: "")
    }
    

    func setListeners() {
        imageView.setOnClickedListener {
            let customCollectionView: CustomCollectionView = UIView.fromNib()
            customCollectionView.translatesAutoresizingMaskIntoConstraints = false
            if let currentVC = RDHelper.getRootViewController() {
                currentVC.view.addSubview(customCollectionView)
                
                let heightConstraint = customCollectionView.heightAnchor.constraint(equalToConstant: 0.0)
                NSLayoutConstraint.activate([customCollectionView.topAnchor.constraint(equalTo: currentVC.view.topAnchor, constant: 0),
                                             customCollectionView.leadingAnchor.constraint(equalTo: currentVC.view.leadingAnchor, constant: 0),
                                             customCollectionView.trailingAnchor.constraint(equalTo: currentVC.view.trailingAnchor, constant: 0),heightConstraint
                                             ])
                                
                currentVC.view.layoutIfNeeded()
                heightConstraint.constant = currentVC.view.frame.height - (currentVC.tabBarController?.tabBar.frame.size.height ?? 0.0)

                UIView.animate(withDuration: 1.0, animations: {
                    currentVC.view.layoutIfNeeded()
                })

            }
        }
    }
}



public protocol ButtonCarouselViewDelegate {
}
