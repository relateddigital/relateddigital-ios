//
//  RDNpsWithNumbersView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit

public class RDNpsWithNumbersView: UIView {


    weak var rdInAppNotification: RDInAppNotification?
    
    init(frame: CGRect, rdInAppNotification: RDInAppNotification?) {
        self.rdInAppNotification = rdInAppNotification
        super.init(frame: frame)
    }

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



    // MARK: - Private functions
    private func createUIElements() {
        //addSubview(collectionView)
    }
    private func installLayoutConstraints() {
        /*NSLayoutConstraint.activate([
            igLeftAnchor.constraint(equalTo: collectionView.igLeftAnchor),
            igTopAnchor.constraint(equalTo: collectionView.igTopAnchor),
            collectionView.igRightAnchor.constraint(equalTo: igRightAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 100)])
         */
    }
}

