//
//  HomeViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS


class HomeViewController: FormViewController {
    
    var textRowItems = ["orgId": relatedDigitalProfile.organizationId, "profileId": relatedDigitalProfile.profileId, "dataSource": relatedDigitalProfile.dataSource, "channel": relatedDigitalProfile.channel, "appAlias": relatedDigitalProfile.appAlias]
    var switchRowItems = ["inAppNotificationsEnabled": relatedDigitalProfile.inAppNotificationsEnabled, "geofenceEnabled": relatedDigitalProfile.geofenceEnabled, "isIDFAEnabled": relatedDigitalProfile.isIDFAEnabled]
    var intRowItems = ["requestTimeoutInSeconds": relatedDigitalProfile.requestTimeoutInSeconds, "geofenceCount": relatedDigitalProfile.maxGeofenceCount]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }
    
    
    fileprivate func addIsTest() -> SwitchRow {
        return SwitchRow("IsTest") {
            $0.title = "IsTest"
            $0.value = relatedDigitalProfile.IsTest
        }.onChange { SwitchRow in
            let orgIdRow: TextRow? = self.form.rowBy(tag: "orgId")
            let profileIdRow: TextRow? = self.form.rowBy(tag: "profileId")
            let dataSourceRow: TextRow? = self.form.rowBy(tag: "dataSource")
            if SwitchRow.value == true {
                orgIdRow?.value = "394A48556A2F76466136733D"
                profileIdRow?.value = "75763259366A3345686E303D"
                dataSourceRow?.value = "mrhp"
            } else {
                orgIdRow?.value = "676D325830564761676D453D"
                profileIdRow?.value = "356467332F6533766975593D"
                dataSourceRow?.value = "visistore"
            }
            orgIdRow?.updateCell()
            profileIdRow?.updateCell()
            dataSourceRow?.updateCell()
        }
    }
    
    func addCreateApiButtonRow() -> ButtonRow {
        return ButtonRow {
            $0.title = "createAPI"
        }.onCellSelection { _, _ in
            let errors = self.form.validate()
            print("Form erros count: \(errors.count), and errors : \(errors)")
            if errors.count > 0 {
                return
            }
            let orgIdRow: TextRow? = self.form.rowBy(tag: "orgId")
            let profileIdRow: TextRow? = self.form.rowBy(tag: "profileId")
            let dataSourceRow: TextRow? = self.form.rowBy(tag: "dataSource")
            let inAppNotificationsEnabledRow: SwitchRow? = self.form.rowBy(tag: "inAppNotificationsEnabled")
            let isTestRow: SwitchRow? = self.form.rowBy(tag: "IsTest")
            let channelRow: TextRow? = self.form.rowBy(tag: "channel")
            let requestTimeoutInSecondsRow: PickerInputRow<Int>? = self.form.rowBy(tag: "requestTimeoutInSeconds")
            let geofenceEnabledRow: SwitchRow? = self.form.rowBy(tag: "geofenceEnabled")
            let idfaRow: SwitchRow? = self.form.rowBy(tag: "isIDFAEnabled")
            let maxGeofenceCountRow: PickerInputRow<Int>? = self.form.rowBy(tag: "maxGeofenceCount")
            let appAliasRow: TextRow? = self.form.rowBy(tag: "appAlias")
            relatedDigitalProfile.organizationId = orgIdRow!.value!
            relatedDigitalProfile.profileId = profileIdRow!.value!
            relatedDigitalProfile.dataSource = dataSourceRow!.value!
            relatedDigitalProfile.geofenceEnabled = geofenceEnabledRow?.value ?? false
            relatedDigitalProfile.isIDFAEnabled = idfaRow?.value ?? false
            relatedDigitalProfile.channel = channelRow!.value!
            relatedDigitalProfile.requestTimeoutInSeconds = requestTimeoutInSecondsRow!.value!
            relatedDigitalProfile.inAppNotificationsEnabled = inAppNotificationsEnabledRow?.value ?? false
            relatedDigitalProfile.IsTest = isTestRow?.value ?? false
            relatedDigitalProfile.maxGeofenceCount = maxGeofenceCountRow?.value ?? 20
            relatedDigitalProfile.appAlias = appAliasRow?.value ?? "VisilabsIOSExample"
            DataManager.saveRelatedDigitalProfile(relatedDigitalProfile)
            /*
            RelatedDigital.createAPI(organizationId: relatedDigitalProfile.organizationId, profileId: relatedDigitalProfile.profileId,
                               dataSource: relatedDigitalProfile.dataSource,
                               inAppNotificationsEnabled: relatedDigitalProfile.inAppNotificationsEnabled,
                               channel: relatedDigitalProfile.channel,
                               requestTimeoutInSeconds: relatedDigitalProfile.requestTimeoutInSeconds,
                               geofenceEnabled: relatedDigitalProfile.geofenceEnabled,
                               maxGeofenceCount: relatedDigitalProfile.maxGeofenceCount,
                               isIDFAEnabled: relatedDigitalProfile.isIDFAEnabled,
                               loggingEnabled: true,isTest: relatedDigitalProfile.IsTest)
            RelatedDigital.callAPI().useInsecureProtocol = false
             */
//            self.configureEuromessage()
            self.goToTabBarController()
        }
    }
    
    func goToTabBarController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getTabBarController()
    }
    
    
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = .white
            headerView.backgroundView?.backgroundColor = .black
            headerView.textLabel?.textColor = .red
        }
    }
    
    private func initializeForm() {
        LabelRow.defaultCellUpdate = { cell, _ in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
            
        }
        
        let sectionOne = Section("createAPI")
        let sectionTwo = Section()
        let sectionThree = Section()
        let sectionFour = Section()
        
        form +++ sectionOne
        <<< addIsTest()
        for (key, value) in textRowItems {
            sectionOne <<< TextRow(key) {
                $0.title = key
                $0.placeholder = value
                $0.value = value
            }.onRowValidationChanged { cell, row in
                let rowIndex = row.indexPath!.row
                while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                    row.section?.remove(at: rowIndex + 1)
                }
                if !row.isValid {
                    for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                        let labelRow = LabelRow {
                            $0.title = validationMsg
                            $0.cell.height = { 30 }
                        }
                        let indexPath = row.indexPath!.row + index + 1
                        row.section?.insert(labelRow, at: indexPath)
                    }
                }
            }
        }
        form +++ sectionTwo
        for (key, value) in switchRowItems {
            sectionTwo <<< SwitchRow(key) {
                $0.title = key
                $0.value = value
            }
        }
        
        form +++ sectionThree
        var count = 0
        for (key, value) in intRowItems {
            sectionThree <<< PickerInputRow<Int>(key) {
                $0.title = key
                $0.options = []
                if count == 0 {
                    for request in 10...60 {
                        $0.options.append(request)
                    }
                    count = 1
                } else {
                    for geofence in 10...20 {
                        $0.options.append(geofence)
                    }
                }
                
                $0.value = value
            }
        }
        
        form +++ sectionFour
        <<< addCreateApiButtonRow()
    }
    
    
}

