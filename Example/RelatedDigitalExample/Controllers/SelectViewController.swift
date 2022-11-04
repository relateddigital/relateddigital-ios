//
//  SelectViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 16.02.2022.
//

import Foundation
import UIKit
import Eureka
import SplitRow
import RelatedDigitalIOS

extension UIViewController {
    func embed(_ viewController:UIViewController, inView view:UIView){
        viewController.willMove(toParent: self)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        self.addChild(viewController)
        viewController.didMove(toParent: self)
    }
}

class SelectViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    func showBannerViewForTest() {
        let bannerView = UIView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bannerView)
        NSLayoutConstraint.activate([bannerView.topAnchor.constraint(equalTo: self.view.topAnchor,constant:  100),
                                     bannerView.heightAnchor.constraint(equalToConstant: 80),
                                     bannerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                     bannerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
        bannerView.backgroundColor = .green
        
        
        var props = Properties()
        props["OM.inapptype"] = "banner_carousel"
        
        RelatedDigital.getBannerView(properties: props) { banner in
            if let banner = banner {
                banner.translatesAutoresizingMaskIntoConstraints = false
                bannerView.addSubview(banner)
                
                NSLayoutConstraint.activate([banner.topAnchor.constraint(equalTo: bannerView.topAnchor),
                                             banner.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
                                             banner.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
                                             banner.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor)])
            }

        }
    }
    
    private func initializeForm() {
        let pushSection = Section("Push Module")
        let analyticsSection = Section("Analytics Module")
        
        form +++ pushSection
        <<< pushButton()
        
        form +++ analyticsSection
        <<< analyticsButton()
        
    }
    
    fileprivate func pushButton() -> ButtonRow {
        return ButtonRow {
            $0.title = "Push Module"
        }.onCellSelection { _, _ in
            self.goToPushViewController()
        }
    }
    
    fileprivate func analyticsButton() -> ButtonRow {
        return ButtonRow {
            $0.title = "Analytics Module"
        }.onCellSelection { _, _ in
            self.goToHomeViewController()
        }
    }
    
    func goToPushViewController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getPushViewController()
    }
    
    func goToHomeViewController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getHomeViewController()
    }
}
