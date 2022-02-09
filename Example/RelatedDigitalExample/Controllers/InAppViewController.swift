//
//  InAppViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import UIKit
import CleanyModal
import RelatedDigitalIOS

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
        if queryStringFilter.lowercased() == RelatedDigitalInAppNotificationType.productStatNotifier.rawValue {
            properties["OM.pv"] = "CV7933-837-837"
        }
        RelatedDigital.callAPI().customEvent("InAppTest", properties: properties)
        RelatedDigital.callAPI().inappButtonDelegate = self
    }
    
    private func getInApps() -> [RelatedDigitalInAppNotificationType: [String: Int]]{
        return [
            .mini: [RelatedDigitalInAppNotificationType.mini.rawValue: 491],
            .full: [RelatedDigitalInAppNotificationType.full.rawValue: 485],
            .imageTextButton: [RelatedDigitalInAppNotificationType.imageTextButton.rawValue: 490],
            .fullImage: [RelatedDigitalInAppNotificationType.fullImage.rawValue: 495],
            .nps: [RelatedDigitalInAppNotificationType.nps.rawValue: 492],
            .imageButton: [RelatedDigitalInAppNotificationType.imageButton.rawValue: 489],
            .smileRating: [RelatedDigitalInAppNotificationType.smileRating.rawValue: 494],
            .emailForm: [RelatedDigitalInAppNotificationType.emailForm.rawValue: 417],
            .alert: ["alert_actionsheet": 487, "alert_native": 540],
            .npsWithNumbers: [RelatedDigitalInAppNotificationType.npsWithNumbers.rawValue: 493],
            .halfScreenImage: [RelatedDigitalInAppNotificationType.halfScreenImage.rawValue: 704],
            .scratchToWin: [RelatedDigitalInAppNotificationType.scratchToWin.rawValue: 592],
            .secondNps: ["nps-image-text-button": 585,  "nps-image-text-button-image": 586, "nps-feedback": 587],
            .spintowin: [RelatedDigitalInAppNotificationType.spintowin.rawValue: 130],
            .productStatNotifier: [RelatedDigitalInAppNotificationType.productStatNotifier.rawValue: 703]
        ]
    }
    
}

extension InAppViewController: VisilabsInappButtonDelegate {
    func didTapButton(_ notification: RelatedDigitalInAppNotification) {
        print("notification did tapped...")
        print(notification)
    }
}
