//
//  FindToWinViewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 29.06.2022.
//

import Foundation


public struct FindToWinViewModel {
    var actId: Int
    var auth: String
    var report: FindToWinReport
    
}

public struct FindToWinReport: Codable {
    var impression: String
    var click: String
}
