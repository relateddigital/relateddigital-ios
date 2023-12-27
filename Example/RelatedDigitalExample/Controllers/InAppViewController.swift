//
//  InAppViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import UIKit
import CleanyModal
import RelatedDigitalIOS
import Eureka
import SplitRow

class InAppViewController: FormViewController, BannerDelegate {

    var propertiesUnitTest = [String: String]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ InAppNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //showButtonCarouselView()
    }
    
    private func  InAppNotifications() -> Section {
        let section = Section("Target Actions".uppercased(with: Locale(identifier: "en_US")))
        for (type, inAppDict)  in getInApps().sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            for (queryStringFilter, actionId) in inAppDict {
                section.append(ButtonRow {
                    $0.title = "TYPE: \(type.rawValue)\n QUERY: \(queryStringFilter)\n ID: \(actionId)"
                }.cellSetup { cell, row in
                    cell.textLabel?.numberOfLines = 0
                }.onCellSelection { _, _ in
                    self.inAppEvent(queryStringFilter)
                })
            }
        }
        return section
    }
    
    func inAppEvent(_ queryStringFilter: String) {
        
        if queryStringFilter == "banner_carousel" {
           _ = showBannerCarousel()
        }
        else {
            var properties = [String: String]()
            properties["OM.inapptype"] = queryStringFilter
            if queryStringFilter.lowercased() == RDInAppNotificationType.productStatNotifier.rawValue {
                properties["OM.pv"] = "CV7933-837-837"
            }
            RelatedDigital.customEvent("InAppTest", properties: properties)
            RelatedDigital.inappButtonDelegate = self
            propertiesUnitTest = properties
        }

    }
    
    
    
    private func getInApps() -> [RDInAppNotificationType: [String: Int]]{
        return [
            .mini: [RDInAppNotificationType.mini.rawValue: 491],
            .full: [RDInAppNotificationType.full.rawValue: 485],
            .imageTextButton: [RDInAppNotificationType.imageTextButton.rawValue: 490],
            .fullImage: [RDInAppNotificationType.fullImage.rawValue: 495],
            .nps: [RDInAppNotificationType.nps.rawValue: 492],
            .imageButton: [RDInAppNotificationType.imageButton.rawValue: 489],
            .smileRating: [RDInAppNotificationType.smileRating.rawValue: 494],
            .emailForm: [RDInAppNotificationType.emailForm.rawValue: 417],
            .alert: ["alert_actionsheet": 487, "alert_native": 540],
            .halfScreenImage: [RDInAppNotificationType.halfScreenImage.rawValue: 704],
            .scratchToWin: [RDInAppNotificationType.scratchToWin.rawValue: 592],
            .secondNps: ["nps-image-text-button": 585,  "nps-image-text-button-image": 586, "nps-feedback": 587],
            .inappcarousel: [RDInAppNotificationType.inappcarousel.rawValue: 927],
            .spintowin: [RDInAppNotificationType.spintowin.rawValue: 562],
            .productStatNotifier: [RDInAppNotificationType.productStatNotifier.rawValue: 703],
            .drawer : [RDInAppNotificationType.drawer.rawValue: 884],
            .downHsView : [RDInAppNotificationType.downHsView.rawValue: 238],
            .video : [RDInAppNotificationType.video.rawValue: 73],
            .gamification : [RDInAppNotificationType.gamification.rawValue: 131],
            .findToWin : [RDInAppNotificationType.findToWin.rawValue: 132],
            .bannerCarousel : [RDInAppNotificationType.bannerCarousel.rawValue: 155],
            .shakeToWin : [RDInAppNotificationType.shakeToWin.rawValue: 255],
            .giftBox : [RDInAppNotificationType.giftBox.rawValue: 577],
            .choosefavorite : [RDInAppNotificationType.choosefavorite.rawValue: 1098],
            .slotMachine : [RDInAppNotificationType.slotMachine.rawValue: 1099],
            .mobileCustomActions : [RDInAppNotificationType.mobileCustomActions.rawValue: 1100],
            .inappRating : [RDInAppNotificationType.inappRating.rawValue: 1101],
            ]
    }
    
}

extension InAppViewController: RDInappButtonDelegate,ButtonCarouselViewDelegate {

    
    func didTapButton(_ notification: RDInAppNotification) {
        print("notification did tapped...")
        print(notification)
    }
    
    func showBannerCarousel() -> UIView {
        let bannerView = UIView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bannerView)
        NSLayoutConstraint.activate([bannerView.topAnchor.constraint(equalTo: self.view.topAnchor,constant:  80),
                                     bannerView.heightAnchor.constraint(equalToConstant: 80),
                                     bannerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                     bannerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
        bannerView.backgroundColor = .black
        
        
        var props = Properties()
        props["OM.inapptype"] = "banner_carousel"
        
        RelatedDigital.getBannerView(properties: props) { banner in
            if let banner = banner {
                banner.delegate = self
                banner.translatesAutoresizingMaskIntoConstraints = false
                bannerView.addSubview(banner)
                
                NSLayoutConstraint.activate([banner.topAnchor.constraint(equalTo: bannerView.topAnchor),
                                             banner.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
                                             banner.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor),
                                             banner.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor)])
            }

        }
        
        return bannerView // For Unit Test Purpose
    }
    
    
    func bannerItemClickListener(url: String) {
        print(url)
    }
    
    
    func showButtonCarouselView() {
        let buttonCarouselView = UIView()
        buttonCarouselView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(buttonCarouselView)
        NSLayoutConstraint.activate([buttonCarouselView.topAnchor.constraint(equalTo: self.view.topAnchor,constant:  80),
                                     buttonCarouselView.heightAnchor.constraint(equalToConstant: 80),
                                     buttonCarouselView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                     buttonCarouselView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
        buttonCarouselView.backgroundColor = .black
        
        
        var props = Properties()
        props["OM.inapptype"] = "button_carousel"
        
        RelatedDigital.getButtonCarouselView(properties: props) { CarouselView in
            if let carView = CarouselView {
                carView.delegate = self
                carView.translatesAutoresizingMaskIntoConstraints = false
                buttonCarouselView.addSubview(carView)
                
                NSLayoutConstraint.activate([carView.topAnchor.constraint(equalTo: buttonCarouselView.topAnchor),
                                             carView.bottomAnchor.constraint(equalTo: buttonCarouselView.bottomAnchor),
                                             carView.leadingAnchor.constraint(equalTo: buttonCarouselView.leadingAnchor),
                                             carView.trailingAnchor.constraint(equalTo: buttonCarouselView.trailingAnchor)])
            }

        }
    }
    


}
