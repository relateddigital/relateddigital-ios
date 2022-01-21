//
//  RelatedDigitalVersion.swift
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

import Foundation;

public class RelatedDigitalVersion : NSObject { // TODO: public olmasına gerek var mı?
    public static let version = "1.0.0"
    
    public class func get() -> String {
        return version
    }
}
