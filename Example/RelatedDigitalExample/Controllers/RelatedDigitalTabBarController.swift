//
//  RelatedDigitalTabBarController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 13.07.2021.
//

import UIKit
import Eureka
import SplitRow

class RelatedDigitalTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let vc1 = AnalyticsViewController()
        vc1.tabBarItem = UITabBarItem(title: "Analytics", image: UIImage(named: "Analytics"), selectedImage: UIImage(named: "Analytics"))
        let vc2 = InAppViewController()
        vc2.tabBarItem = UITabBarItem(title: "Target Actions", image: UIImage(named: "InApp"), selectedImage: UIImage(named: "InApp"))
        let vc3 = StoryViewController()
        vc3.tabBarItem = UITabBarItem(title: "Story", image: UIImage(named: "story"), selectedImage: UIImage(named: "story"))
        let vc4 = GeofenceViewController()
        vc4.tabBarItem = UITabBarItem(title: "Geofence", image: UIImage(named: "Geofence"), selectedImage: UIImage(named: "Geofence"))
        let vc5 = RecommendationViewController()
        vc5.tabBarItem = UITabBarItem(title: "Recommendation", image: UIImage(named: "reco"), selectedImage: UIImage(named: "reco"))
        let vc6 = FavoriteViewController()
        vc6.tabBarItem = UITabBarItem(title: "Favorite Attribute", image: UIImage(named: "favorite"), selectedImage: UIImage(named: "favorite"))
        viewControllers = [vc1, vc2, vc3, vc4, vc5, vc6]
    }
    
    
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected \(tabBarController.title ?? "NULL" )")
    }


}
