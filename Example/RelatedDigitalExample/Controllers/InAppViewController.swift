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

class InAppViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ InAppNotifications()
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
    
    private func inAppEvent(_ queryStringFilter: String) {
        var properties = [String: String]()
        properties["OM.inapptype"] = queryStringFilter
        if queryStringFilter.lowercased() == RDInAppNotificationType.productStatNotifier.rawValue {
            properties["OM.pv"] = "CV7933-837-837"
        }
        RelatedDigital.customEvent("InAppTest", properties: properties)
        RelatedDigital.inappButtonDelegate = self
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
            .npsWithNumbers: [RDInAppNotificationType.npsWithNumbers.rawValue: 493],
            .halfScreenImage: [RDInAppNotificationType.halfScreenImage.rawValue: 704],
            .scratchToWin: [RDInAppNotificationType.scratchToWin.rawValue: 592],
            .secondNps: ["nps-image-text-button": 585,  "nps-image-text-button-image": 586, "nps-feedback": 587],
            .inappcarousel: [RDInAppNotificationType.inappcarousel.rawValue: 927],
            .spintowin: [RDInAppNotificationType.spintowin.rawValue: 130],
            .productStatNotifier: [RDInAppNotificationType.productStatNotifier.rawValue: 703],
            .drawer : [RDInAppNotificationType.drawer.rawValue: 203],
            .downHsView : [RDInAppNotificationType.downHsView.rawValue: 238],
            .video : [RDInAppNotificationType.video.rawValue: 73]
        ]
    }
    
}

extension InAppViewController: RDInappButtonDelegate {
    func didTapButton(_ notification: RDInAppNotification) {
        print("notification did tapped...")
        print(notification)
    }
}
