//
//  RDStoryPreviewView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

public enum RDLayoutType {
    case cubic
    case parallax
    var animator: LayoutAttributesAnimator {
        switch self {
        case .cubic:return CubeAttributesAnimator(perspective: -1/100, totalAngle: .pi/12)
        case .parallax: return ParallaxAttributesAnimator()
        }
    }
}

class RDStoryPreviewView: UIView {

    // MARK: - iVars
    var layoutType: RDLayoutType?
    // swiftlint:disable large_tuple
    /**Layout Animate options(ie.choose which kinda animation you want!)*/
    lazy var layoutAnimator: (LayoutAttributesAnimator, Bool, Int, Int) = (layoutType!.animator, true, 1, 1)
    lazy var snapsCollectionViewFlowLayout: AnimatedCollectionViewLayout = {
        let flowLayout = AnimatedCollectionViewLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.animator = layoutAnimator.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        return flowLayout
    }()
    lazy var snapsCollectionView: UICollectionView! = {
        let colView = UICollectionView.init(frame: CGRect(x: 0, y: 0,
                                    width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                    collectionViewLayout: snapsCollectionViewFlowLayout)
        colView.backgroundColor = .black
        colView.showsVerticalScrollIndicator = false
        colView.showsHorizontalScrollIndicator = false
        colView.register(RDStoryPreviewCell.self,
                forCellWithReuseIdentifier: RDStoryPreviewCell.reuseIdentifier)
        colView.translatesAutoresizingMaskIntoConstraints = false
        colView.isPagingEnabled = true
        colView.isPrefetchingEnabled = false
        colView.collectionViewLayout = snapsCollectionViewFlowLayout
        return colView
    }()

    // MARK: - Overridden functions
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    convenience init(layoutType: RDLayoutType) {
        self.init()
        self.layoutType = layoutType
        createUIElements()
        installLayoutConstraints()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Private functions
    private func createUIElements() {
        backgroundColor = .black
        addSubview(snapsCollectionView)
    }
    private func installLayoutConstraints() {
        // Setting constraints for snapsCollectionview
        NSLayoutConstraint.activate([
            igLeftAnchor.constraint(equalTo: snapsCollectionView.igLeftAnchor),
            igTopAnchor.constraint(equalTo: snapsCollectionView.igTopAnchor),
            snapsCollectionView.igRightAnchor.constraint(equalTo: igRightAnchor),
            snapsCollectionView.igBottomAnchor.constraint(equalTo: igBottomAnchor)])
    }
}
