//
//  VisilabsDefaultPopupNotificationViewController.swift
//  VisilabsIOS
//
//  Created by Egemen on 8.06.2020.
//

import UIKit
import AVFoundation
// swiftlint:disable type_name
final public class RelatedDigitalDefaultPopupNotificationViewController: UIViewController {

    weak var relatedDigitalInAppNotification: RDInAppNotification?
    var mailForm: MailSubscriptionViewModel?
    var scratchToWin: ScratchToWinModel?
    var player : AVPlayer?

    convenience init(relatedDigitalInAppNotification: RDInAppNotification? = nil,
                     emailForm: MailSubscriptionViewModel? = nil,
                     scratchToWin: ScratchToWinModel? = nil) {
        self.init()
        self.relatedDigitalInAppNotification = relatedDigitalInAppNotification
        self.mailForm = emailForm
        self.scratchToWin = scratchToWin

        
        if let image = relatedDigitalInAppNotification?.image {
            if let imageGif = UIImage.gif(data: image) {
                self.image = imageGif
            } else {
                self.image = UIImage(data: image)
            }
        }

        if let img = scratchToWin?.image {
            self.image = UIImage(data: img)
        }

        if let secondImage = relatedDigitalInAppNotification?.secondImage2 {
            self.secondImage = UIImage.gif(data: secondImage)
        }
    }

    public var standardView: RDPopupDialogDefaultView {
       return view as! RDPopupDialogDefaultView // swiftlint:disable:this force_cast
    }

    override public func loadView() {
        super.loadView()
        view = RDPopupDialogDefaultView(frame: .zero,
                                              visilabsInAppNotification: relatedDigitalInAppNotification,
                                              emailForm: mailForm,
                                              scratchTW: scratchToWin)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //player = standardView.imageView.addVideoPlayer(urlString: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
}

public extension RelatedDigitalDefaultPopupNotificationViewController {

    // MARK: - Setter / Getter

    // MARK: Content

    /// The dialog image
    var image: UIImage? {
        get { return standardView.imageView.image }
        set {
            standardView.imageView.image = newValue
            standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView()
        }
    }
    /// Second Image View
    var secondImage: UIImage? {
        get { return standardView.secondImageView.image }
        set {
            standardView.secondImageView.image = newValue
            standardView.secondImageHeight?.constant = standardView.imageView.pv_heightForImageView()
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
        standardView.imageHeightConstraint?.constant = standardView.imageView.pv_heightForImageView()
        standardView.secondImageHeight?.constant = standardView.secondImageView.pv_heightForImageView()
        if let _ = self.scratchToWin {
            standardView.sctw.centerX(to: standardView)
        }
    }
}
