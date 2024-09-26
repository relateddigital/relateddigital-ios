//
//  HomeViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS
import Eureka
import SplitRow


class HomeViewController: FormViewController {
    
    var switchRowItems = ["inAppNotificationsEnabled": relatedDigitalProfile.inAppNotificationsEnabled, "geofenceEnabled": relatedDigitalProfile.geofenceEnabled,"TestApp": relatedDigitalProfile.testUrlIsActive]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }
    
    func sliceListener() {
        NotificationCenter.default.addObserver(forName: Notification.Name("InAppLink"), object: nil, queue: .main) { notification in
            if let userInfo = notification.userInfo, let link = userInfo["link"] as? String {
                print("Received InAppLink: \(link)")
            }
        }
    }
    
    fileprivate func changePage() -> SplitRow<ButtonRow, ButtonRow> {
        return SplitRow() {
            $0.rowLeftPercentage = 0.5
            
            $0.rowLeft = ButtonRow {
                $0.title = "Push Module"
            }.onCellSelection({ cell, row in
                self.goToPushViewController()
            })
            
            $0.rowRight = ButtonRow {
                $0.title = "Analytics Module"
                $0.disabled = true
            }
        }
    }
    
    func addCreateApiButtonRow() -> ButtonRow {
        return ButtonRow {
            $0.title = "Initialize Related Digital"
        }.onCellSelection { _, _ in
            let errors = self.form.validate()
            print("Form erros count: \(errors.count), and errors : \(errors)")
            if errors.count > 0 {
                return
            }
            let inAppNotificationsEnabledRow: SwitchRow? = self.form.rowBy(tag: "inAppNotificationsEnabled")
            let geofenceEnabledRow: SwitchRow? = self.form.rowBy(tag: "geofenceEnabled")
            relatedDigitalProfile.geofenceEnabled = geofenceEnabledRow?.value ?? false
            relatedDigitalProfile.inAppNotificationsEnabled = inAppNotificationsEnabledRow?.value ?? false
            RelatedDigital.inAppNotificationsEnabled = relatedDigitalProfile.inAppNotificationsEnabled
            RelatedDigital.geofenceEnabled = relatedDigitalProfile.geofenceEnabled
            let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.isRelatedInit = true
        
            let testUrlIsActive: SwitchRow? = self.form.rowBy(tag: "TestApp")

            if testUrlIsActive?.value == true {
                UrlConstant.shared.setTestWithLocalData(isActive: true)
            } else {
                UrlConstant.shared.setTestWithLocalData(isActive: false)
            }
            self.goToTabBarController()
        }
    }
    
    func goToTabBarController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getTabBarController()
    }
    
    
    private func initializeForm() {
        LabelRow.defaultCellUpdate = { cell, _ in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
            
        }
        
        form +++ Section("Change Page")
        <<< changePage()
        
        let sectionOne = Section("Modules")
        
        form +++ sectionOne
        for (key, value) in switchRowItems {
            sectionOne <<< SwitchRow(key) {
                $0.title = key
                $0.value = value
            }
        }
        
        form +++ Section()
        <<< addCreateApiButtonRow()
    }
    
    func goToPushViewController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getPushViewController()
    }
    
}

