//
//  downhsViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 13.04.2022.
//

import UIKit

class downHsViewController: RDBaseNotificationViewController, UITextFieldDelegate {

    var globDownhsView : downhsView?
    var model = downHsModel()
    var position: CGPoint?
    var shouldDismissed = false
    var keyBoardHeight = 200.0
    var keyBooardOpen = false
    var consentConfirmed = false
    var mailConfirmed = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init(model:downHsViewServiceModel?) {
        super.init(nibName: nil, bundle: nil)
        let downhsView : downhsView = UIView.fromNib()
        globDownhsView = downhsView
        self.globDownhsView?.mailTextField.delegate = self
        self.model = downHsViewControllerModel().mapServiceModelToNeededModel(serviceModel: model!)
        self.view = downhsView
        configureView()
        addTargets()
        assignInfos()
    }
    
    func assignInfos() {
        
        globDownhsView?.leftImageVİew.setImage(withUrl: model.image ?? "")
        globDownhsView?.rightImageView.setImage(withUrl: model.image ?? "")
        globDownhsView?.titleLabel.text = model.serviceModel?.title
        globDownhsView?.consentLabel.text = model.serviceModel?.consentText
        globDownhsView?.mailPermitLabel.text = model.serviceModel?.emailPermitText
        globDownhsView?.mailErrLabel.text = model.serviceModel?.invalidEmailMessage
        globDownhsView?.consentErrLabel.text = model.serviceModel?.checkConsentMessage
        globDownhsView?.mailTextField.placeholder = model.serviceModel?.placeholder
        globDownhsView?.submitButton.setTitle(model.serviceModel?.buttonLabel, for: .normal)
        if model.serviceModel?.closeButtonColor == "white" {
            globDownhsView?.closeButton.setTitleColor(.white, for: .normal)
        }
        setDesign()
    }
    
    func setDesign() {
        
        let titleFont = RDHelper.getFont(fontFamily: model.serviceModel?.titleFontFamily, fontSize: model.serviceModel?.titleTextSize, style: .title2, customFont: model.serviceModel?.titleCustomFontFamilyIos)
        let titleColor = UIColor(hex: model.serviceModel?.titleTextColor)
        globDownhsView?.titleLabel.font = titleFont
        globDownhsView?.titleLabel.textColor = titleColor
        
        let subTitleFont = RDHelper.getFont(fontFamily: model.serviceModel?.textFontFamily, fontSize: model.serviceModel?.textSize, style: .title2, customFont: model.serviceModel?.textCustomFontFamilyIos)
        let subTitleColor = UIColor(hex: model.serviceModel?.textColor)
        
        globDownhsView?.subTitleUpLabel.font = subTitleFont
        globDownhsView?.subTitleUpLabel.textColor = subTitleColor
        
        let consentLabelFont = RDHelper.getFont(fontFamily: model.serviceModel?.titleFontFamily, fontSize: model.serviceModel?.consentTextSize, style: .title2)
        globDownhsView?.consentLabel.font = consentLabelFont
        
        let mailPermitLabelFont = RDHelper.getFont(fontFamily: model.serviceModel?.titleFontFamily, fontSize: model.serviceModel?.emailPermitTextSize, style: .title2)
        globDownhsView?.mailPermitLabel.font = mailPermitLabelFont

        let submitButtonFont = RDHelper.getFont(fontFamily: model.serviceModel?.buttonFontFamily, fontSize: model.serviceModel?.buttonTextSize, style: .title2, customFont: model.serviceModel?.buttonCustomFontFamilyIos)
        let submitButtonTextColor = UIColor(hex: model.serviceModel?.buttonTextColor)
        let submitButtonBackGroundColor = UIColor(hex: model.serviceModel?.buttonColor)

        let viewBackGroundColor = UIColor(hex: model.serviceModel?.backgroundColor)
        globDownhsView?.downHsBackGroundView.backgroundColor = viewBackGroundColor
        
        globDownhsView?.submitButton.setTitleColor(submitButtonTextColor, for: .normal)
        globDownhsView?.submitButton.backgroundColor = submitButtonBackGroundColor
        globDownhsView?.submitButton.titleLabel?.font = submitButtonFont
        globDownhsView?.submitButton.layer.cornerRadius = 10
        
        globDownhsView?.emailPermitCheckBoxImageView.superview?.layer.borderWidth = 2.0
        globDownhsView?.emailPermitCheckBoxImageView.superview?.layer.borderColor = UIColor.lightGray.cgColor
        
        globDownhsView?.consentPermitCheckBoxImageView.superview?.layer.borderWidth = 2.0
        globDownhsView?.consentPermitCheckBoxImageView.superview?.layer.borderColor = UIColor.lightGray.cgColor
 
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func addTargets() {
        
        globDownhsView?.submitButton.addTarget(self, action:#selector(submitClicked(sender:)), for: .touchUpInside)
        globDownhsView?.closeButton.addTarget(self, action:#selector(closeClicked(sender:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(downHsViewController.tapFunctionConsent))
        globDownhsView?.consentLabel.isUserInteractionEnabled = true
        globDownhsView?.consentLabel.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(downHsViewController.tapFunctionMail))
        globDownhsView?.mailPermitLabel.isUserInteractionEnabled = true
        globDownhsView?.mailPermitLabel.addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(downHsViewController.consentImageTapped(tapGestureRecognizer:)))
        globDownhsView?.consentPermitCheckBoxImageView.isUserInteractionEnabled = true
        globDownhsView?.consentPermitCheckBoxImageView.addGestureRecognizer(tap3)
        
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(downHsViewController.mailImageTapped(tapGestureRecognizer:)))
        globDownhsView?.emailPermitCheckBoxImageView.isUserInteractionEnabled = true
        globDownhsView?.emailPermitCheckBoxImageView.addGestureRecognizer(tap4)
    }
    
    @objc func consentImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if consentConfirmed {
            globDownhsView?.consentPermitCheckBoxImageView.image = UIImage()
            consentConfirmed = false
        } else {
            globDownhsView?.consentPermitCheckBoxImageView.image = UIImage(named: "grayTick.png", in: Bundle(for: type(of: self)), compatibleWith: nil)
            consentConfirmed = true
        }
    }
    
    @objc func mailImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if mailConfirmed {
            globDownhsView?.emailPermitCheckBoxImageView.image = UIImage()
            mailConfirmed = false
        } else {
            globDownhsView?.emailPermitCheckBoxImageView.image = UIImage(named: "grayTick.png", in: Bundle(for: type(of: self)), compatibleWith: nil)

            mailConfirmed = true
        }
    }
    
    @objc func tapFunctionConsent(sender:UITapGestureRecognizer) {
        if let url = URL(string: model.serviceModel?.consentTextUrl ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func tapFunctionMail(sender:UITapGestureRecognizer) {
        if let url = URL(string: model.serviceModel?.emailPermitTextUrl ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func keyboardWillAppear(_ notification: Notification) {
        if !keyBooardOpen {
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                self.keyBoardHeight = keyboardHeight
            }
            setViewUp()
            keyBooardOpen = true
        }
    }

    @objc func keyboardWillDisappear() {
        keyBooardOpen = false
        setViewDown()
    }
    
    @objc func submitClicked(sender: UIButton) {
        
        if !isValidEmail(globDownhsView?.mailTextField.text ?? "") {
            globDownhsView?.mailErrLabel.isHidden = false
            return
        } else {
            globDownhsView?.mailErrLabel.isHidden = true
        }

        if mailConfirmed && consentConfirmed {
            RelatedDigital.subscribeMail(click: "",actid: "\(model.serviceModel?.actId ?? 0)", auth: model.serviceModel?.auth ?? "", mail: globDownhsView?.mailTextField.text ?? "")
            globDownhsView?.mailErrLabel.isHidden = false
            globDownhsView?.mailErrLabel.textColor = .green
            globDownhsView?.mailErrLabel.text = model.serviceModel?.successMessage
            globDownhsView?.submitButton.isUserInteractionEnabled = false
        } else {
            if !consentConfirmed {
                globDownhsView?.consentErrLabel.isHidden = false
            }
        }
    }
    
    @objc func closeClicked(sender: UIButton){
        shouldDismissed = true
        delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    

    
    func setViewUp() {
        UIView.animate(withDuration: 0.5, animations: { [self] in
            if let winPos = self.window?.layer.position {
                self.window?.layer.position = CGPoint(x: winPos.x , y: winPos.y - keyBoardHeight)
            }
        })
    }
    
    func setViewDown() {
        UIView.animate(withDuration: 0.5, animations: { [self] in
            if let winPos = self.window?.layer.position {
                self.window?.layer.position = CGPoint(x: winPos.x , y: winPos.y + keyBoardHeight)
            }
        })
    }
    
    func configureView() {
        let bounds = UIScreen.main.bounds
        if model.imagePos == .right {
            globDownhsView?.leftImageViewWidth.constant = 0
            globDownhsView?.rightImageViewWidth.constant = bounds.width / 3
        } else {
            globDownhsView?.rightImageViewWidth.constant = 0
            globDownhsView?.leftImageViewWidth.constant = bounds.width / 3
        }
        
        if model.textPos == .top {
            globDownhsView?.subTitleDownLabel.isHidden = true
            globDownhsView?.subTitleUpLabel.text = model.serviceModel?.message
        } else {
            globDownhsView?.subTitleUpLabel.isHidden = true
            globDownhsView?.subTitleDownLabel.text = model.serviceModel?.message
        }
        globDownhsView?.consentLabel.isHidden = model.lastTextHidden
        globDownhsView?.closeButton.layer.zPosition = 10
        
        globDownhsView?.consentView.isHidden = model.consentCheckBoxIsHidden
        globDownhsView?.emailPermitView.isHidden = model.emailCheckBoxIsHidden
        
        if globDownhsView?.consentView.isHidden == true{
            consentConfirmed = true
        }

        if globDownhsView?.emailPermitView.isHidden == true {
            mailConfirmed = true
        }
    }
    
    override func show(animated: Bool) {
        guard let sharedUIApplication = RDInstance.sharedUIApplication() else {
            return
        }
        var bounds: CGRect
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                           .connectedScenes
                           .filter { $0.activationState == .foregroundActive }
                           .first
            guard let scene = windowScene as? UIWindowScene else { return }
            bounds = scene.coordinateSpace.bounds
        } else {
            bounds = UIScreen.main.bounds
        }
        let bottomInset = Double(RDHelper.getSafeAreaInsets().bottom)
        let downhsViewHeight = 400.0
        
        let frameY = bounds.maxY - downhsViewHeight + bottomInset
        
        
        let frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(frameY)), size: CGSize(width: bounds.size.width, height: CGFloat(downhsViewHeight)))
        
        if #available(iOS 13.0, *) {
            let windowScene = sharedUIApplication
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first
            if let windowScene = windowScene as? UIWindowScene {
                window = UIWindow(frame: frame)
                window?.windowScene = windowScene
            }
        } else {
            window = UIWindow(frame: frame)
        }

        if let window = window {
            window.windowLevel = UIWindow.Level.alert
            window.clipsToBounds = false // true
            window.rootViewController = self
            window.isHidden = false
        }
        self.position = self.window?.layer.position
    }
    
    override func hide(animated: Bool, completion: @escaping () -> Void) {
        
        if shouldDismissed {
            self.window?.isHidden = true
            self.window?.removeFromSuperview()
            self.window = nil
            completion()
        }
    }
}
