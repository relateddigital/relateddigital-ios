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
        
        globDownhsView?.leftImageVİew.image = model.image
        globDownhsView?.rightImageView.image = model.image
        globDownhsView?.titleLabel.text = model.serviceModel?.title
        globDownhsView?.lastTextLabel.text = model.serviceModel?.emailPermitText
        globDownhsView?.mailTextField.placeholder = model.serviceModel?.placeholder
        globDownhsView?.submitButton.setTitle(model.serviceModel?.buttonLabel, for: .normal)
        //globDownhsView?.closeButton
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
        
        let lastTextLabelFont = RDHelper.getFont(fontFamily: model.serviceModel?.emailPermitTextSize, fontSize: model.serviceModel?.titleTextSize, style: .title2)
        globDownhsView?.titleLabel.font = lastTextLabelFont

        
        let submitButtonFont = RDHelper.getFont(fontFamily: model.serviceModel?.buttonFontFamily, fontSize: model.serviceModel?.buttonTextSize, style: .title2, customFont: model.serviceModel?.buttonCustomFontFamilyIos)
        let submitButtonTextColor = UIColor(hex: model.serviceModel?.buttonTextColor)
        let submitButtonBackGroundColor = UIColor(hex: model.serviceModel?.buttonColor)

        let viewBackGroundColor = UIColor(hex: model.serviceModel?.backgroundColor)
        globDownhsView?.downHsBackGroundView.backgroundColor = viewBackGroundColor
        
        globDownhsView?.submitButton.setTitleColor(submitButtonTextColor, for: .normal)
        globDownhsView?.submitButton.backgroundColor = submitButtonBackGroundColor
        globDownhsView?.submitButton.titleLabel?.font = submitButtonFont
        globDownhsView?.submitButton.layer.cornerRadius = 10
 
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func addTargets() {
        globDownhsView?.closeButton.addTarget(self, action:#selector(closeClicked(sender:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)

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
    
    @objc func closeClicked(sender: UIButton){
        shouldDismissed = true
        delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
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
        globDownhsView?.lastTextLabel.isHidden = model.lastTextHidden
        globDownhsView?.closeButton.layer.zPosition = 10
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

        let downhsViewHeight = 350.0
        
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
