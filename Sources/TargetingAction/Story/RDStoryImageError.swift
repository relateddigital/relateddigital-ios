//
//  RDStoryImageError.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation

public enum RDStoryImageError: Error, CustomStringConvertible {

    case invalidImageURL
    case downloadError

    public var description: String {
        switch self {
        case .invalidImageURL: return "Invalid Image URL"
        case .downloadError: return "Unable to download image"
        }
    }
}
