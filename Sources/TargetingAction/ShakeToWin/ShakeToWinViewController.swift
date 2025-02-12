//
//  ShakeToWinViewController.swift
//  VisilabsIOS
//
//  Created by Said Alır on 5.04.2021.
//

import UIKit
import AVFoundation
import AVKit

class ShakeToWinViewController: RDBaseNotificationViewController {

    var model: ShakeToWinViewModel?
    let scrollView = UIScrollView()
    var multiplier = 0.0
    weak var player: AVPlayer?
    var mailFormExist = true
    var firstChecked = false
    var secondChecked = false
    var lastPageOpened = false
    var audioPlayer: AVPlayer?
    var confirmedMail : String?

    var openedSecondPage = false {
        didSet {
            self.deviceDidntShake()
        }
    }

    var didShake = false {
        didSet {
            self.openThirdPage(self.model?.secondPage?.waitSeconds ?? 0)
        }
    }

    lazy var mainButton: UIButton = {
        let button = UIButton()
        button.setTitle(model?.firstPage?.buttonText, for: .normal)
        button.backgroundColor = model?.firstPage?.buttonBgColor
        button.titleLabel?.font = model?.firstPage?.buttonFont
        button.titleLabel?.textColor = model?.firstPage?.buttonTextColor
        return button
    }()

    init(model: ShakeToWinViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.model = model
        self.shakeToWin = model

        if model.mailForm.title?.count ?? 0 > 0 && model.mailForm.title != nil {
            mailFormExist = true
        } else {
            mailFormExist = false
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(scrollView)
    }

    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && openedSecondPage && !didShake {
            self.didShake = true
        }
    }

    public override func viewDidLayoutSubviews() {
        scrollView.frame = self.view.frame
        if scrollView.subviews.count == 2 {
            checkMailIsAvaliable()
            configureScrollView()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loopAudio()
        playAudio()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.pause()
        audioPlayer = nil
    }

    func checkMailIsAvaliable() {
        if mailFormExist == true {
            multiplier = 1.0
        }
    }

    func configureScrollView() {
        if mailFormExist == true {
            scrollView.contentSize = CGSize(width: view.frame.width*4, height: view.frame.height)
            scrollView.addSubview(prepareMailPage())
        } else {
            scrollView.contentSize = CGSize(width: view.frame.width*3, height: view.frame.height)
        }
        scrollView.isPagingEnabled = false
        scrollView.isScrollEnabled = false

        scrollView.addSubview(prepareFirstPage())
        scrollView.addSubview(prepareSecondPage())
        scrollView.addSubview(prepareThirdPage())
    }

    @objc func closeButtonTapped(_ sender: UIButton) {

        close()
    }

    func close() {
        dismiss(animated: true) {
            if let shakeToWin = self.shakeToWin {
                if self.lastPageOpened {
                    if shakeToWin.bannercodeShouldShow ?? false {
                        self.codeGotten()
                        let bannerVC = RDShakeToWinCodeBannerController(shakeToWin)
                        bannerVC.delegate = self.delegate
                        bannerVC.show(animated: true)
                    }
                }
                self.removeViewsForSomeUI()
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            } else {
                self.removeViewsForSomeUI()
                self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            }
        }
    }
    
    func removeViewsForSomeUI() {
        self.scrollView.isHidden = true
        self.scrollView.removeFromSuperview()
        let subViews = self.view.subviews
        
        for element in subViews {
            element.removeFromSuperview()
        }
    }

    func getUIImage(named: String) -> UIImage? {
        
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle(for: ShakeToWinViewController.self)
#endif
        
        if let image = UIImage(named: named, in: bundle, compatibleWith: nil)!.resized(withPercentage: CGFloat(0.75)) {
            return image
        } else {
            return UIImage()
        }
    }

    func deviceDidntShake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            if self.didShake == false {
                self.openThirdPage(0)
            }
        })
    }

    func openThirdPage(_ delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(delay)) {
            BannerCodeManager.shared.setShakeToWinCode(code: self.model?.thirdPage?.staticCode ?? "")
            self.lastPageOpened = true
            self.scrollView.setContentOffset(CGPoint(x: self.view.frame.size.width*(self.multiplier+2), y: 0.0), animated: true)
            if let p = self.player {
                p.pause()
                self.player = nil
            }
        }
    }

    
    func codeGotten() {
        let actionID = self.shakeToWin?.actId
        var properties = Properties()
        properties[RDConstants.promoActionID] = String(actionID ?? 0)
        properties[RDConstants.promoEmailKey] = confirmedMail
        properties[RDConstants.promoAction] = self.model?.thirdPage?.staticCode ?? ""
        RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
    }
    
    func prepareMailPage() -> UIView {
        let page: MailFormView = .fromNib()

        page.secondLineTicImageView.layer.cornerRadius = 8
        page.secondLineTicImageView.layer.borderWidth = 0.3
        page.secondLineTicImageView.layer.borderColor = UIColor.black.cgColor

        page.firstLineTickImageView.layer.cornerRadius = 10
        page.firstLineTickImageView.layer.borderWidth = 0.5
        page.firstLineTickImageView.layer.borderColor = UIColor.black.cgColor

        page.continueButtonView.layer.cornerRadius = 10

        page.frame = CGRect(x: 0,
                            y: 0,
                            width: view.frame.width,
                            height: view.frame.height)

        if let bgImg = self.model?.backGroundImage {
            page.setBackGround(url: bgImg)
        }

        page.backgroundColor = model?.firstPage?.backgroundColor
        let close = getCloseButton()
        page.addSubview(close)
        close.top(to: page, offset: 50)
        close.trailing(to: page, offset: -20)
        close.width(40)
        close.height(40)

        page.titleLabel.text = model?.mailForm.title?.replacingOccurrences(of: "\\n", with: "\n")
        page.titleLabel.font = RDHelper.getFont(fontFamily: model?.mailExtendedProps.titleFontFamily, fontSize: model?.mailExtendedProps.titleTextSize, style: .title2)
        page.titleLabel.textColor = UIColor(hex: model?.mailExtendedProps.titleTextColor)

        page.subTİtleLabel.text = model?.mailForm.message?.replacingOccurrences(of: "\\n", with: "\n")
        page.subTİtleLabel.font = RDHelper.getFont(fontFamily: model?.mailExtendedProps.textFontFamily, fontSize: model?.mailExtendedProps.textSize, style: .title2)
        page.subTİtleLabel.textColor = UIColor(hex: model?.mailExtendedProps.textColor)

        page.firsLineTickLabel.text = model?.mailForm.emailPermitText?.replacingOccurrences(of: "\\n", with: "\n")
        page.firsLineTickLabel.font = RDHelper.getFont(fontFamily: "default", fontSize: model?.mailExtendedProps.emailPermitTextSize, style: .body)
        page.firsLineTickLabel.textColor = .black

        page.secondLineTickLabel.text = model?.mailForm.consentText?.replacingOccurrences(of: "\\n", with: "\n")
        page.secondLineTickLabel.font = RDHelper.getFont(fontFamily: "default", fontSize: model?.mailExtendedProps.consentTextSize, style: .body)
        page.secondLineTickLabel.textColor = .black

        page.firstLineWarningLabel.text = model?.mailForm.emailPermitText?.replacingOccurrences(of: "\\n", with: "\n")
        page.secondLineWarningLabel.text = model?.mailForm.checkConsentMessage?.replacingOccurrences(of: "\\n", with: "\n")

        page.mailTextView.attributedPlaceholder = NSAttributedString(string: model?.mailForm.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])

        page.continueButtonView.backgroundColor = UIColor(hex: model?.mailExtendedProps.buttonColor)
        page.continueButtonLabel.textColor = UIColor(hex: model?.mailExtendedProps.buttonTextColor)
        page.continueButtonLabel.text = model?.mailForm.buttonTitle?.replacingOccurrences(of: "\\n", with: "\n")
        page.continueButtonLabel.font = RDHelper.getFont(fontFamily: model?.mailExtendedProps.buttonFontFamily, fontSize: model?.mailExtendedProps.buttonTextSize, style: .body)

        page.mailInvalidLabel.text = model?.mailForm.invalidEmailMessage?.replacingOccurrences(of: "\\n", with: "\n")
        page.secondLineWarningLabel.text = model?.mailForm.checkConsentMessage?.replacingOccurrences(of: "\\n", with: "\n")

        page.firsLineTickLabel.setOnClickedListener {
            if let url = URL(string: self.model?.mailExtendedProps.emailPermitTextUrl ?? "") {
                UIApplication.shared.open(url)
            }
        }

        page.secondLineTickLabel.setOnClickedListener {
            if let url = URL(string: self.model?.mailExtendedProps.consentTextUrl ?? "") {
                UIApplication.shared.open(url)
            }
        }

        page.firstLineTickImageView.setOnClickedListener { [self] in
            firstChecked = !firstChecked
            if firstChecked {
                page.firstLineTickImageView.image = getUIImage(named: "tickImage")
            } else {
                page.firstLineTickImageView.image = UIImage()
            }
        }

        page.secondLineTicImageView.setOnClickedListener { [self] in
            secondChecked = !secondChecked
            if secondChecked {
                page.secondLineTicImageView.image = getUIImage(named: "tickImage")
            } else {
                page.secondLineTicImageView.image = UIImage()
            }
        }

        page.continueButtonView.setOnClickedListener { [self] in
            let mail = page.mailTextView.text ?? ""
            if !RDHelper.checkEmail(email: mail) {
                page.mailInvalidLabel.isHidden = false
                return
            }

            if !firstChecked {
                // page.firstLineWarningLabel.isHidden = false
            }

            if !secondChecked {
                page.secondLineWarningLabel.isHidden = false
            }

            if firstChecked && secondChecked {
                confirmedMail = mail
                RelatedDigital.subscribeMail(click: self.model!.report?.click ?? "",
                                             actid: "\(self.model!.actId ?? 0)",
                                             auth: self.model!.auth ?? "",
                                             mail: mail)
                scrollView.setContentOffset(CGPoint(x: view.frame.size.width, y: 0.0), animated: true)
            }

        }

        return page
    }

    func prepareFirstPage() -> UIView {
        let page = UIView(frame: CGRect(x: view.frame.width*multiplier,
                                        y: 0,
                                        width: view.frame.width,
                                        height: view.frame.height))

        var imageView = UIImageView(frame: .zero)

        if let bgImg = self.model?.backGroundImage {
            page.setBackGround(url: bgImg)
        }

        if let firstPage = model?.firstPage {
            var imageAdded = false
            if let img = firstPage.image {
                imageView = UIImageView(frame: .zero)

                page.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    
                    imageView.centerYAnchor.constraint(equalTo: page.centerYAnchor),
                    imageView.centerXAnchor.constraint(equalTo: page.centerXAnchor),
                    imageView.topAnchor.constraint(equalTo: page.topAnchor),
                    imageView.bottomAnchor.constraint(equalTo: page.bottomAnchor),
                    imageView.leadingAnchor.constraint(equalTo: page.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: page.trailingAnchor)
                ])
                page.bringSubviewToFront(imageView)
                imageView.setImageWithImageSize(withUrl: img)
                imageView.contentMode = .scaleToFill
                imageAdded = true
            }
            let title = UILabel(frame: .zero)
            title.text = model?.firstPage?.title?.replacingOccurrences(of: "\\n", with: "\n")
            title.textColor = model?.firstPage?.titleColor
            title.font = model?.firstPage?.titleFont
            title.numberOfLines = 0
            page.addSubview(title)
            title.height(40.0)
            title.centerX(to: page)
            if imageAdded {
                title.topToBottom(of: imageView, offset: 10)
            } else {
                title.top(to: page, offset: 20)
            }

            let message = UILabel(frame: .zero)
            message.text = model?.firstPage?.message?.replacingOccurrences(of: "\\n", with: "\n")
            message.textColor = model?.firstPage?.messageColor
            message.font = model?.firstPage?.messageFont
            message.textAlignment = .center
            message.numberOfLines = 0
            page.addSubview(message)

            message.centerX(to: page)
            message.topToBottom(of: title, offset: 5)
            message.height(0.0)

            let button = UIButton(frame: .zero)
            button.setTitle(model?.firstPage?.buttonText, for: .normal)
            button.setTitleColor(model?.firstPage?.buttonTextColor, for: .normal)
            button.titleLabel?.font = model?.firstPage?.buttonFont
            button.backgroundColor = model?.firstPage?.buttonBgColor
            page.addSubview(button)

            button.height(60.0)
            button.centerX(to: page)
            //button.topToBottom(of: message, offset: 10)
            button.bottom(to: page, offset: -20)
            button.width(120.0,relation: .equalOrGreater)
            button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)

            button.addTarget(self, action: #selector(goSecondPage), for: .touchUpInside)
        }

        page.backgroundColor = model?.firstPage?.backgroundColor
        let close = getCloseButton()
        page.addSubview(close)
        close.top(to: page, offset: 50)
        close.trailing(to: page, offset: -20)
        close.width(40)
        close.height(40)

        close.setOnClickedListener {
            self.close()
        }

        return page
    }

    func prepareSecondPage() -> UIView {
        let page = UIView(frame: CGRect(x: view.frame.width*(multiplier+1),
                                        y: 0,
                                        width: view.frame.width,
                                        height: view.frame.height))

        if let bgImg = self.model?.backGroundImage {
            page.setBackGround(url: bgImg)
        }

        page.backgroundColor = model?.secondPage?.backGroundColor

        if let videoUrl = model?.secondPage?.videoURL {
            if videoUrl.absoluteString.contains(".gif") {
                let gifImageview = UIImageView()
                gifImageview.translatesAutoresizingMaskIntoConstraints = false
                page.addSubview(gifImageview)

                NSLayoutConstraint.activate([gifImageview.centerXAnchor.constraint(equalTo: page.centerXAnchor),
                                             gifImageview.centerYAnchor.constraint(equalTo: page.centerYAnchor),
                                             gifImageview.leadingAnchor.constraint(equalTo: page.leadingAnchor, constant: 0.0),
                                             gifImageview.trailingAnchor.constraint(equalTo: page.trailingAnchor, constant: 0.0)])

                gifImageview.setImageWithImageSize(withUrl: videoUrl.absoluteString)
                gifImageview.contentMode = .scaleToFill
            } else {
                let player = AVPlayer(url: videoUrl)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = page.bounds
                playerLayer.videoGravity = .resizeAspectFill
                page.layer.addSublayer(playerLayer)
                self.player = player

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    player.play()
                }
            }
        }

        let close = getCloseButton()
        page.addSubview(close)
        close.top(to: page, offset: 50)
        close.trailing(to: page, offset: -20)
        close.width(40)
        close.height(40)
        close.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)

        page.bringSubviewToFront(close)

        return page
    }

    func prepareThirdPage() -> UIView {
        let page: CupponCodePageView = .fromNib()
        page.copyButtonView.layer.cornerRadius = 10
        page.cupponCodeView.layer.cornerRadius = 10
        page.goLinkVİew.layer.cornerRadius = 10

        page.frame = CGRect(x: view.frame.width*(multiplier+2),
                            y: 0,
                            width: view.frame.width,
                            height: view.frame.height)

        if let bgImg = self.model?.backGroundImage {
            page.setBackGround(url: bgImg)
        }

        page.coppyButtonLabel.text = model?.thirdPage?.buttonText?.replacingOccurrences(of: "\\n", with: "\n")
        page.coppyButtonLabel.textColor = model?.thirdPage?.buttonTextColor
        page.coppyButtonLabel.font = model?.thirdPage?.buttonFont
        page.copyButtonView.backgroundColor = model?.thirdPage?.buttonBgColor
        page.cupponCodeLabel.text = model?.thirdPage?.staticCode
        page.cupponCodeLabel.textColor =  UIColor(hex: model?.promocode_text_color)
        page.cupponCodeView.backgroundColor = UIColor(hex: model?.promocode_background_color)

        page.copyButtonView.setOnClickedListener {
            self.copyClicked()
        }

        page.titleLabel.text = model?.thirdPage?.title?.replacingOccurrences(of: "\\n", with: "\n")
        page.titleLabel.textColor = model?.thirdPage?.titleColor
        page.titleLabel.font = model?.thirdPage?.titleFont
        page.subTitleLabel.text = model?.thirdPage?.message?.replacingOccurrences(of: "\\n", with: "\n")
        page.subTitleLabel.textColor = model?.thirdPage?.messageColor
        page.subTitleLabel.font = model?.thirdPage?.messageFont
        page.backgroundColor = model?.thirdPage?.backgroundColor
        
        
        let close = getCloseButton()
        page.addSubview(close)
        close.top(to: page, offset: 50)
        close.trailing(to: page, offset: -20)
        close.width(40)
        close.height(40)
        close.setOnClickedListener {
            self.close()
        }
        return page
    }

    func copyClicked() {
        UIPasteboard.general.string = model?.thirdPage?.staticCode
        RDHelper.showCopiedClipboardMessage()
        BannerCodeManager.shared.setShakeToWinCode(code: model?.thirdPage?.staticCode ?? "")
        close()
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            if let url = URL(string: self.model?.thirdPage?.iosLink ?? "") {
                UIApplication.shared.open(url)
            }
        }
    }

    override func show(animated: Bool) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication() else {
            return
        }
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first
            if let windowScene = windowScene as? UIWindowScene {
                window = UIWindow(frame: windowScene.coordinateSpace.bounds)
                window?.windowScene = windowScene
            }
        } else {
            window = UIWindow(frame: CGRect(x: 0,
                                            y: 0,
                                            width: UIScreen.main.bounds.size.width,
                                            height: UIScreen.main.bounds.size.height))
        }
        if let window = window {
            window.alpha = 0
            window.windowLevel = UIWindow.Level.alert
            window.rootViewController = self
            window.isHidden = false
        }

        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.window?.alpha = 1
            }, completion: { _ in
        })
    }

    override func hide(animated: Bool, completion: @escaping () -> Void) {
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.window?.alpha = 0
            }, completion: { _ in
                self.view.isHidden = true
                self.window?.isHidden = true
                self.window?.removeFromSuperview()
                self.window = nil
                completion()
        })
    }
}

extension ShakeToWinViewController {

//    func createDummyModel() -> ShakeToWinViewModel? {
//        var img: UIImage? = nil
//        if let data = getImageDataOfUrl(URL(string: "https://placekitten.com/300/500")) {
//            img = UIImage(data: data)
//        }
//
//        return ShakeToWinViewModel(targetingActionType: .shakeToWin, mailForm: nil,firstPage: ShakeToWinFirstPage(image: "img", title: "shtw first page", titleFont: .boldSystemFont(ofSize: 16), titleColor: .yellow, message: "shtw message \n message can be plural", messageColor: .white, messageFont: .systemFont(ofSize: 12), buttonText: "hit me for next", buttonTextColor: .blue, buttonFont: .boldSystemFont(ofSize: 16), buttonBgColor: .white, backgroundColor: .green, closeButtonColor: .white),
//                                   secondPage: ShakeToWinSecondPage(waitSeconds: 8, videoURL: URL(string: "https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-1232-large.mp4"), closeButtonColor: .white),
//                                   thirdPage: ShakeToWinThirdPage(image: nil, title: "third page", titleFont: .boldSystemFont(ofSize: 16), titleColor: .darkGray, message: "shtw message \n message can be plural", messageColor: .blue, messageFont: .italicSystemFont(ofSize: 12), buttonText: "finish", buttonTextColor: .white, buttonFont: .boldSystemFont(ofSize: 16), buttonBgColor: .black, backgroundColor: .systemPink, closeButtonColor: .white))
//    }

    @objc func goSecondPage() {
        scrollView.setContentOffset(CGPoint(x: view.frame.size.width*(multiplier+1), y: 0.0), animated: true)
        self.openedSecondPage = true
        if let p = self.player {
            p.play()
        }
    }

    func getCloseButton() -> UIButton {
        let button = UIButton()
        button.setImage(getUIImage(named: "VisilabsCloseButton"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)

        if self.model?.closeButtonColor == "black" {
            button.setImage(getUIImage(named: "VisilabsCloseButtonBlack"), for: .normal)
        }
        return button
    }

}

extension UIView {
    func setBackGround(url: String) {

        let bgImageView = UIImageView()
        bgImageView.setImage(withUrl: url)
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(bgImageView)
        bgImageView.layer.zPosition = -100
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: self.topAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)])
    }
}

extension ShakeToWinViewController {
    func playAudio() {

        guard let url = URL.init(string: self.model?.soundUrl ?? "") else { return }
        let playerItem = AVPlayerItem.init(url: url)
        audioPlayer = AVPlayer.init(playerItem: playerItem)
        audioPlayer?.play()
    }

    func loopAudio() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in
            self.audioPlayer?.seek(to: CMTime.zero)
            self.audioPlayer?.play()
        }
    }
}
