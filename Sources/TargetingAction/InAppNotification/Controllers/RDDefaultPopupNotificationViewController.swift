//
//  RDDefaultPopupNotificationViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 8.06.2020.
//

import UIKit
import AVFoundation
// swiftlint:disable type_name
public final class RDDefaultPopupNotificationViewController: UIViewController {

    weak var rdInAppNotification: RDInAppNotification?
    var mailForm: MailSubscriptionViewModel?
    var scratchToWin: ScratchToWinModel?
    var player : AVPlayer?

    convenience init(rdInAppNotification: RDInAppNotification? = nil,
                     emailForm: MailSubscriptionViewModel? = nil,
                     scratchToWin: ScratchToWinModel? = nil) {
        self.init()
        self.rdInAppNotification = rdInAppNotification
        self.mailForm = emailForm
        self.scratchToWin = scratchToWin
        

        if let image = rdInAppNotification?.image ?? scratchToWin?.image {
            if let imageGif = UIImage.gif(data: image) {
                self.image = imageGif
            } else {
                self.image = UIImage(data: image)
            }
        }

        if let secondImage = rdInAppNotification?.secondImage2 {
            self.secondImage = UIImage.gif(data: secondImage)
        }
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
            player = standardView.imageView.addVideoPlayer(urlString: rdInAppNotification?.videourl ?? "")
            if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 || rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 {
                inAppCurrentState.shared.isFirstPageOpened = true
            }
        } else {
            if rdInAppNotification?.secondPopupVideourl1?.count ?? 0 > 0 {
                player = standardView.imageView.addVideoPlayer(urlString: rdInAppNotification?.secondPopupVideourl1 ?? "")
            }
            
            if rdInAppNotification?.secondPopupVideourl2?.count ?? 0 > 0 {
                player = standardView.secondImageView.addVideoPlayer(urlString: rdInAppNotification?.secondPopupVideourl2 ?? "")
            }
            inAppCurrentState.shared.isFirstPageOpened = false
        }        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
}

public extension RDDefaultPopupNotificationViewController {

    // MARK: - Setter / Getter

    // MARK: Content

    /// The dialog image
    var image: UIImage? {
        get { return standardView.imageView.image }
        set {
            standardView.imageView.image = newValue
            if rdInAppNotification?.videourl?.count ?? 0 > 0 {
                standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
            } else {
                standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
            }
        }
    }
    /// Second Image View
    var secondImage: UIImage? {
        get { return standardView.secondImageView.image }
        set {

            standardView.secondImageView.image = newValue
            if rdInAppNotification?.videourl?.count ?? 0 > 0 {
                standardView.secondImageHeight?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: true)
            } else {
                standardView.secondImageHeight?.constant = standardView.imageView.pv_heightForImageView(isVideoExist: false)
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

    /// The title text of the dialog
    var titleText: String? {
        get { return standardView.titleLabel.text }
        set {
            standardView.titleLabel.text = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The message text of the dialog
    var messageText: String? {
        get { return standardView.messageLabel.text }
        set {
            standardView.messageLabel.text = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    // MARK: Appearance

    /// The font and size of the title label
    @objc dynamic var titleFont: UIFont {
        get { return standardView.titleFont }
        set {
            standardView.titleFont = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The color of the title label
    @objc dynamic var titleColor: UIColor? {
        get { return standardView.titleLabel.textColor }
        set {
            standardView.titleColor = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The text alignment of the title label
    @objc dynamic var titleTextAlignment: NSTextAlignment {
        get { return standardView.titleTextAlignment }
        set {
            standardView.titleTextAlignment = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The font and size of the body label
    @objc dynamic var messageFont: UIFont {
        get { return standardView.messageFont}
        set {
            standardView.messageFont = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The color of the message label
    @objc dynamic var messageColor: UIColor? {
        get { return standardView.messageColor }
        set {
            standardView.messageColor = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
    }

    /// The text alignment of the message label
    @objc dynamic var messageTextAlignment: NSTextAlignment {
        get { return standardView.messageTextAlignment }
        set {
            standardView.messageTextAlignment = newValue
            standardView.pv_layoutIfNeededAnimated()
        }
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
