//
//  PushViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 16.02.2022.
//

import Eureka
import Foundation
import RelatedDigitalIOS
import SplitRow
import UIKit

class PushViewController: FormViewController {
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }

    private func initializeForm() {
        let segmentedSection = Section("Change Page")
        let askPermissionSection = Section("Ask Permission")
        let switchPermissionSection = Section("Permissions")
        let setSection = Section("Set")

        form +++ segmentedSection
            <<< changePage()

        form +++ askPermissionSection
            <<< askForNotificationPermission()
            <<< askForProvisionalNotificationPermission()

        form +++ switchPermissionSection
            <<< pushPermission()
            <<< gsmPermission()
            <<< emailPermission()

        form +++ setSection
            <<< setEmail()
            <<< sendSubscription()
            <<< userProperty()
            <<< removeUserProperty()

        form +++ Section()
            <<< getPushMessages()
            <<< getPushMessagesWithID()
    }

    fileprivate func changePage() -> SplitRow<ButtonRow, ButtonRow> {
        return SplitRow {
            $0.rowLeftPercentage = 0.5

            $0.rowLeft = ButtonRow {
                $0.title = "Push Module"
                $0.disabled = true
            }

            $0.rowRight = ButtonRow {
                $0.title = "Analytics Module"
            }.onCellSelection({ _, _ in
                if self.appDelegate?.isRelatedInit == false {
                    self.goToHomeViewController()
                } else {
                    self.goToTabBarController()
                }

            })
        }
    }

    fileprivate func askForNotificationPermission() -> ButtonRow {
        return ButtonRow {
            $0.title = "Ask For Push Notification Permission"
        }.onCellSelection { _, _ in
            RelatedDigital.askForNotificationPermission(register: true)
        }.cellSetup { cell, _ in
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        }
    }

    fileprivate func askForProvisionalNotificationPermission() -> ButtonRow {
        return ButtonRow {
            $0.title = "Ask For Push Notification Permission Provisional"
        }.onCellSelection { _, _ in
            RelatedDigital.askForNotificationPermissionProvisional(register: true)
        }.cellSetup { cell, _ in
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        }
    }

    fileprivate func pushPermission() -> SwitchRow {
        return SwitchRow("pushPermission") {
            $0.title = "Push Permission: null"
            $0.value = false
        }.onChange { SwitchRow in
            RelatedDigital.setPushNotification(permission: SwitchRow.value!)
            if SwitchRow.value == true {
                #if targetEnvironment(simulator)
                    RelatedDigital.registerToken(tokenData: Data(base64Encoded: "dG9rZW4="))
                #else
                    RelatedDigital.registerForPushNotifications()
                #endif
                SwitchRow.title = "Push Permission: Y"
            } else {
                SwitchRow.title = "Push Permission: N"
            }
        }
    }

    fileprivate func gsmPermission() -> SwitchRow {
        return SwitchRow("gsmPermission") {
            $0.title = "GSM Permission: null"
            $0.value = false
        }.onChange { SwitchRow in
            RelatedDigital.setPhoneNumber(permission: SwitchRow.value!)
        }
    }

    fileprivate func emailPermission() -> SwitchRow {
        return SwitchRow("emailPermission") {
            $0.title = "Email Permission: null"
            $0.value = false
        }.onChange { SwitchRow in
            RelatedDigital.setEmail(permission: SwitchRow.value!)
        }
    }

    fileprivate func setEmail() -> TextRow {
        return TextRow("email") {
            $0.title = "Email"
            $0.placeholder = "Please enter your e-mail"
        }
    }

    fileprivate func sendSubscription() -> ButtonRow {
        return ButtonRow {
            $0.title = "Set"
        }.onCellSelection { _, _ in
            let email: TextRow = self.form.rowBy(tag: "email") as! TextRow
            RelatedDigital.setEmail(email: email.value, permission: true)
            RelatedDigital.sync()
        }
    }

    fileprivate func userProperty() -> TextRow {
        return TextRow("property") {
            $0.title = "Remove User Property"
            $0.placeholder = "Please enter property"
        }
    }

    fileprivate func removeUserProperty() -> ButtonRow {
        return ButtonRow {
            $0.title = "Remove"
        }.onCellSelection { _, _ in
            let userProperty: TextRow = self.form.rowBy(tag: "property") as! TextRow
            RelatedDigital.removeUserProperty(key: userProperty.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
            RelatedDigital.sync()
        }
    }

    fileprivate func getPushMessages() -> ButtonRow {
        return ButtonRow {
            $0.title = "Get Push Messages"
        }.onCellSelection { _, _ in
            RelatedDigital.getPushMessages { messages in
                if messages.isEmpty {
                    print("🚲 there is no recorded push message.")
                }

                for message in messages {
                    print("🆔: \(message.pushId ?? "")")
                    print("📅: \(message.formattedDateString ?? "")")
                    print(message.encoded)
                }
            }
        }
    }
    
    fileprivate func getPushMessagesWithID() -> ButtonRow {
        return ButtonRow {
            $0.title = "Get Push Messages With ID"
        }.onCellSelection { _, _ in
            RelatedDigital.getPushMessagesWithID { messages in
                if messages.isEmpty {
                    print("🚲 there is no recorded push message.")
                }

                for message in messages {
                    print("🆔: \(message.pushId ?? "")")
                    print("📅: \(message.formattedDateString ?? "")")
                    print(message.encoded)
                }
            }
        }
    }

    func goToHomeViewController() {
        view.window?.rootViewController = appDelegate?.getHomeViewController()
    }

    func goToTabBarController() {
        view.window?.rootViewController = appDelegate?.getTabBarController()
    }
}
