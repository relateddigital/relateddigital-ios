//
//  ViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let b = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 100))
        b.backgroundColor = UIColor.red
        view.addSubview( b)
        // Do any additional setup after loading the view.
        
        RelatedDigital.callAPI().tryLog(logType: 1, message: "deb")
        RelatedDigital.callAPI().tryLog(logType: 2, message: "infosss")
        RelatedDigital.callAPI().tryLog(logType: 3, message: "warr")
        RelatedDigital.callAPI().tryLog(logType: 4, message: "ERRR")
    }


}

