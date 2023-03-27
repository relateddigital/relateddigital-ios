//
//  RDNpsWithNumbersDefaultViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 15.03.2023.
//

import UIKit
import AVFoundation

// swiftlint:disable type_name
public final class RDNpsWithNumbersDefaultViewController: UIViewController {
    
    weak var rdInAppNotification: RDInAppNotification?
    var player : AVPlayer?
    
    convenience init(rdInAppNotification: RDInAppNotification? = nil) {
        self.init()
        self.rdInAppNotification = rdInAppNotification
        
        self.image = UIImage()
    }
    
    public var standardView: RDNpsWithNumbersCollectionView {
        return view as! RDNpsWithNumbersCollectionView // swiftlint:disable:this force_cast
    }
    
    override public func loadView() {
        super.loadView()
        view = RDNpsWithNumbersCollectionView(frame: .zero,
                                              rdInAppNotification: rdInAppNotification)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player = standardView.imageView.addVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
}

public extension RDNpsWithNumbersDefaultViewController {
    
    
    var image: UIImage? {
        get { return standardView.imageView.image }
        set {
            if rdInAppNotification?.videourl?.count ?? 0 > 0 {
                standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
            } else {
                standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
                standardView.imageView.setImage(withUrl: rdInAppNotification?.imageUrl)
            }
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if rdInAppNotification?.videourl?.count ?? 0 > 0 {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
        } else {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
        }
                
    }
}

