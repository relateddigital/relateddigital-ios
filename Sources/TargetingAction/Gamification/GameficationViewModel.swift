//
//  gameficationViewModel.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 23.05.2022.
//

import Foundation


public struct GameficationViewModel {
    var actId: Int
    var auth: String
    var report: GameficationReport
    
}

public struct GameficationReport: Codable {
    var impression: String
    var click: String
}
