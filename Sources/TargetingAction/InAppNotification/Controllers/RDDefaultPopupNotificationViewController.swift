//
//  RDDefaultPopupNotificationViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 8.06.2020.
//

import UIKit
import AVFoundation
import WebKit
// swiftlint:disable type_name
public final class RDDefaultPopupNotificationViewController: UIViewController {
    
    weak var rdInAppNotification: RDInAppNotification?
    var mailForm: MailSubscriptionViewModel?
    var scratchToWin: ScratchToWinModel?
    var player : AVPlayer?
    var webPlayer : WKWebView?
    
    convenience init(rdInAppNotification: RDInAppNotification? = nil,
                     emailForm: MailSubscriptionViewModel? = nil,
                     scratchToWin: ScratchToWinModel? = nil) {
        self.init()
        self.rdInAppNotification = rdInAppNotification
        self.mailForm = emailForm
        self.scratchToWin = scratchToWin
        
        self.image = UIImage()
        self.secondImage = UIImage()
    }
    
    public var standardView: RDPopupDialogDefaultView {
        return view as! RDPopupDialogDefaultView // swiftlint:disable:this force_cast
    }
    
    override public func loadView() {
        super.loadView()
        view = RDPopupDialogDefaultView(frame: .zero,
                                        rdInAppNotification: rdInAppNotification,
                                        emailForm: mailForm,
                                        scratchTW: scratchToWin)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !inAppCurrentState.shared.isFirstPageOpened {
            webPlayer = standardView.imageView.addYoutubeVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
            player = standardView.imageView.addVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
            if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 || rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 || rdInAppNotification?.secondPopupTitle?.count ?? 0 > 0 {
                inAppCurrentState.shared.isFirstPageOpened = true
            }
        } else {
            if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 {
                player = standardView.imageView.addVideoPlayer(urlString: rdInAppNotification?.secondPopupVideourl1 ?? "")
                webPlayer = standardView.imageView.addYoutubeVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
            }
            
            if rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 {
                player = standardView.secondImageView.addVideoPlayer(urlString: rdInAppNotification?.secondPopupVideourl2 ?? "")
                webPlayer = standardView.secondImageView.addYoutubeVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
            }
            inAppCurrentState.shared.isFirstPageOpened = false
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        webPlayer?.stopPlayer()
    }
}

public extension RDDefaultPopupNotificationViewController {
    
    // MARK: - Setter / Getter
    
    // MARK: Content
    
    /// The dialog image
    var image: UIImage? {
        get { return standardView.imageView.image }
        set {
            if inAppCurrentState.shared.isFirstPageOpened == true {
                if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 {
                    standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
                } else {
                    standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
                    standardView.imageView.setImage(withUrl: rdInAppNotification?.secondImageUrl1)
                }
            } else {
                if rdInAppNotification?.videourl?.count ?? 0 > 0 {
                    standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
                } else {
                    standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
                    standardView.imageView.setImage(withUrl: rdInAppNotification?.imageUrl)
                }
            }

        }
    }
    /// Second Image View
    var secondImage: UIImage? {
        get { return standardView.secondImageView.image }
        set {
            
            if rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 {
                standardView.secondImageHeight?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
            } else {
                standardView.secondImageHeight?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
                standardView.secondImageView.setImage(withUrl: rdInAppNotification?.secondImageUrl2)
            }
        }
    }
    
    // TO_DO: hideTitle ve hideMessage kaldırılabilir sanırım.
    func hideTitle() {
        standardView.titleLabel.isHidden = true
    }
    
    func hideMessage() {
        standardView.messageLabel.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if rdInAppNotification?.videourl?.count ?? 0 > 0 {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
        } else {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
        }
        
        if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 && inAppCurrentState.shared.isFirstPageOpened {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
        } else if inAppCurrentState.shared.isFirstPageOpened {
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
        }
        
        if rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 && inAppCurrentState.shared.isFirstPageOpened {
            standardView.secondImageHeight?.constant = standardView.secondImageView.pv_heightForImageView(isVideoExist: true)
        } else if inAppCurrentState.shared.isFirstPageOpened {
            standardView.secondImageHeight?.constant = standardView.secondImageView.pv_heightForImageView(isVideoExist: false)
        }
        
        
        if let _ = self.scratchToWin {
            standardView.sctw.centerX(to: standardView)
        }
    }
}
