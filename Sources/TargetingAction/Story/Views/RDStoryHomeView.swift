//
//  RDStoryHomeView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

public class RDStoryHomeView: UIView {

    private var collectionHeightConstraint: NSLayoutConstraint!

    // MARK: - iVars
    lazy var layout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 80, height: 100)
        return flowLayout
    }()
    lazy var collectionView: UICollectionView = {
        let colView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        colView.backgroundColor = .clear // .orange // .white
        colView.showsVerticalScrollIndicator = false
        colView.showsHorizontalScrollIndicator = false
        colView.register(RDStoryHomeViewCell.self,
                         forCellWithReuseIdentifier: RDStoryHomeViewCell.reuseIdentifier)
        colView.translatesAutoresizingMaskIntoConstraints = false
        return colView
    }()

    // MARK: - Overridden functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // UIColor.white // UIColor.rgb(from: 0xEFEFF4)
        createUIElements()
        installLayoutConstraints()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }

    public var controller: RDStoryHomeViewController?

    func setDelegates() {
        self.collectionView.delegate = controller
        self.collectionView.dataSource = controller
    }

    // MARK: - Private functions
    private func createUIElements() {
        addSubview(collectionView)
    }
    private func installLayoutConstraints() {
        
        collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            igLeftAnchor.constraint(equalTo: collectionView.igLeftAnchor),
            igTopAnchor.constraint(equalTo: collectionView.igTopAnchor),
            collectionView.igRightAnchor.constraint(equalTo: igRightAnchor),
            collectionHeightConstraint])
    }
    
    public func updateCollectionHeight() {
         if StoryProps.shared.properties.shape == "Rectangle" {
             collectionHeightConstraint.constant = 300
         } else {
             collectionHeightConstraint.constant = 100
         }
         layoutIfNeeded()
     }
}
