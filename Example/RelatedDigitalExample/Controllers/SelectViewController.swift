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

class SelectViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
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
