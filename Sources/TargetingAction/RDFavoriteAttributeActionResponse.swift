//
//  RDFavoriteAttributeActionResponse.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

public class RDFavoriteAttributeActionResponse {
    public var favorites: [RDFavoriteAttribute: [String]]
    public var error: RDError?

    internal init(favorites: [RDFavoriteAttribute: [String]], error: RDError? = nil) {
        self.favorites = favorites
        self.error = error
    }
}
