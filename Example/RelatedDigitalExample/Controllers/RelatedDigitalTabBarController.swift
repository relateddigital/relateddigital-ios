//
//  RelatedDigitalTabBarController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 13.07.2021.
//

import UIKit

class RelatedDigitalTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let vc1 = AnalyticsViewController()
        vc1.tabBarItem = UITabBarItem(title: "Analytics Tab Bar", image: UIImage(named: "Analytics"), selectedImage: UIImage(named: "Analytics"))
        let vc2 = GeofenceViewController()
        vc2.tabBarItem = UITabBarItem(title: "Geofence Tab Bar", image: UIImage(named: "Geofence"), selectedImage: UIImage(named: "Geofence"))
        viewControllers = [vc1, vc2]
    }
    
    
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Selected \(viewController.title ?? "NULL" )")
    }


}
