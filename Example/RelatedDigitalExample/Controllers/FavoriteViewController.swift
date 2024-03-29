//
//  FavoriteViewController.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 9.02.2022.
//

import Foundation
import UIKit
import RelatedDigitalIOS
import CleanyModal
import Eureka
import SplitRow

class FavoriteViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }
    
    private func initializeForm() {
        form +++
            Section("Favorite Attribute Actions".uppercased(with: Locale(identifier: "en_US")))
            +++
            ButtonRow {
                $0.title = "getFavoriteAttributeActions"
            }.onCellSelection { _, _ in
                self.getFavoriteAttributeActions()
            }
    }



    private func getFavoriteAttributeActions() {
        RelatedDigital.getFavoriteAttributeActions { (response) in
            if let error = response.error {
                print(error)
            } else {
                if let favoriteBrands = response.favorites[.brand] {
                    for brand in favoriteBrands {
                        print(brand)
                    }
                }
                if let favoriteCategories = response.favorites[.category] {
                    for category in favoriteCategories {
                        print(category)
                    }
                }
            }
        }
    }

    private func getFavoriteAttributeActions2() {
        RelatedDigital.getFavoriteAttributeActions(actionId: 188) { (response) in
            if let error = response.error {
                print(error)
            } else {
                if let favoriteBrands = response.favorites[.brand] {
                    for brand in favoriteBrands {
                        print(brand)
                    }
                }
                if let favoriteCategories = response.favorites[.category] {
                    for category in favoriteCategories {
                        print(category)
                    }
                }
            }
        }
    }

}
