//
//  VisilabsFavoriteAttributeActionResponse.swift
//  VisilabsIOS
//
//  Created by Egemen on 25.08.2020.
//

public class RelatedDigitalFavoriteAttributeActionResponse {
    public var favorites: [RelatedDigitalFavoriteAttribute: [String]]
    public var error: RelatedDigitalError?

    internal init(favorites: [RelatedDigitalFavoriteAttribute: [String]], error: RelatedDigitalError? = nil) {
        self.favorites = favorites
        self.error = error
    }
}
