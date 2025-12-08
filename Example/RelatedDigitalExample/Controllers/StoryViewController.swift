//
//  StoryViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 9.02.2022.
//

import UIKit
import CleanyModal
import RelatedDigitalIOS
import Eureka
import SplitRow

class StoryViewController: UIViewController, UITextFieldDelegate {
    var actionIdTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.placeholder = "Action Id(optional)"
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemBlue.cgColor
        textField.layer.cornerRadius = 10
        textField.textAlignment = .center
        textField.text = "305"
        return textField
    }()
    
    var storyAsyncButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.setTitle("Show Story Async", for: .normal)
        return button
    }()
    
    var npsWithNumbersButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.setTitle("Nps Numbers Async", for: .normal)
        return button
    }()
    
    var npsView: RDNpsWithNumbersContainerView?
    var storyHomeView: RDStoryHomeView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        actionIdTextField.delegate = self
        actionIdTextField.addTarget(self, action: #selector(self.textFieldFilter), for: .editingChanged)
        storyAsyncButton.addTarget(self, action: #selector(showStoryAsync), for: .touchUpInside)
        npsWithNumbersButton.addTarget(self, action: #selector(showNpsWithNumbersAsync), for: .touchUpInside)
        self.view.addSubview(actionIdTextField)
        self.view.addSubview(storyAsyncButton)
        self.view.addSubview(npsWithNumbersButton)
        setupLayout()
    }
    
    private func setupLayout() {
        actionIdTextField.translatesAutoresizingMaskIntoConstraints = false
        actionIdTextField.widthAnchor.constraint(equalToConstant: 150).isActive = true
        actionIdTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        actionIdTextField.topAnchor.constraint(equalTo: view.saferAreaLayoutGuide.topAnchor,
                                               constant: 20).isActive = true
        actionIdTextField.centerXAnchor.constraint(equalTo: view.saferAreaLayoutGuide.centerXAnchor,
                                                   constant: 0).isActive = true
        
        storyAsyncButton.translatesAutoresizingMaskIntoConstraints = false
        storyAsyncButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        storyAsyncButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        storyAsyncButton.topAnchor.constraint(equalTo: actionIdTextField.bottomAnchor, constant: 20).isActive = true
        storyAsyncButton.centerXAnchor.constraint(equalTo: view.saferAreaLayoutGuide.centerXAnchor,constant: 0).isActive = true
        
        npsWithNumbersButton.translatesAutoresizingMaskIntoConstraints = false
        npsWithNumbersButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        npsWithNumbersButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        npsWithNumbersButton.topAnchor.constraint(equalTo: storyAsyncButton.bottomAnchor, constant: 20).isActive = true
        npsWithNumbersButton.centerXAnchor.constraint(equalTo: view.saferAreaLayoutGuide.centerXAnchor,constant: 0).isActive = true
    }
    
    @objc private func textFieldFilter(_ textField: UITextField) {
        if let text = textField.text, let intText = Int(text), intText > 0 {
            if text.count > 4 {
                textField.text = String(text.prefix(4))
            } else {
                textField.text = "\(intText)"
            }
        } else {
            textField.text = ""
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @objc func showStoryAsync(sender: UIButton) {
        RelatedDigital.getStoryViewAsync(actionId: Int(self.actionIdTextField.text ?? "")){ storyHomeView in
            DispatchQueue.main.async {
                self.npsView?.removeFromSuperview()
                self.storyHomeView?.removeFromSuperview()
                if let storyHomeView = storyHomeView {
                    self.storyHomeView = storyHomeView
                    storyHomeView.controller?.urlDelegate = self
                    self.view.addSubview(storyHomeView)
                    storyHomeView.translatesAutoresizingMaskIntoConstraints = false
                    storyHomeView.topAnchor.constraint(equalTo: self.npsWithNumbersButton.bottomAnchor, constant: 20).isActive = true
                    storyHomeView.widthAnchor.constraint(equalTo: self.view.saferAreaLayoutGuide.widthAnchor).isActive = true
                    storyHomeView.heightAnchor.constraint(equalToConstant: 400).isActive = true
                } else {
                    print("There is no story action matching your criteria.")
                }
            }
            
        }
    }
    
    @objc func showNpsWithNumbersAsync(sender: UIButton) {
        
        var props = [String: String]()
        props["OM.inapptype"] = "nps_with_numbers"
        self.storyHomeView?.removeFromSuperview()
        self.npsView?.removeFromSuperview()
        
        RelatedDigital.getNpsWithNumbersView(properties: props, delegate: self){ npsView in
            DispatchQueue.main.async {
                
                if let npsView = npsView {
                    self.npsView = npsView
                    self.view.addSubview(npsView)
                    npsView.translatesAutoresizingMaskIntoConstraints = false
                    npsView.topAnchor.constraint(equalTo: self.npsWithNumbersButton.bottomAnchor, constant: -50).isActive = true
                    npsView.widthAnchor.constraint(equalTo: self.view.saferAreaLayoutGuide.widthAnchor).isActive = true
                    npsView.heightAnchor.constraint(equalToConstant: 550).isActive = true
                } else {
                    print("There is no nps action matching your criteria.")
                }
            }
        }
    }
    
}

extension UIView {
    var saferAreaLayoutGuide: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide
        } else {
            return self.layoutMarginsGuide
        }
    }
}

extension StoryViewController: RDStoryURLDelegate {
    func urlClicked(_ url: URL) {
        print("You can handle url as you like!")
    }
}

extension StoryViewController: RDNpsWithNumbersDelegate {
    func npsItemClicked(npsLink: String?) {
        self.npsView?.removeFromSuperview()
        
        let alertController = UIAlertController(title: "Nps Clicked", message: npsLink, preferredStyle: .alert)
        let close = UIAlertAction(title: "Close", style: .destructive) { _ in
            print("dismiss tapped")
        }
        alertController.addAction(close)
        self.present(alertController, animated: true)
    }
}
