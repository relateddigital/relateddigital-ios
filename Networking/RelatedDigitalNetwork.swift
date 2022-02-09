//
//  RelatedDigitalNetwork.swift
//  RelatedDigitalIOS
//
//  Created by Umut Can ALPARSLAN on 21.10.2021.
//

import Foundation

enum RelatedDigitalRequestMethod: String {
    case get
    case post
}

enum RelatedDigitalEndpoint {
    case logger
    case realtime
    case target
    case action
    case geofence
    case mobile
    case subsjson
    case promotion
    case remote
}

struct RelatedDigitalResource<A> {
    let endPoint: RelatedDigitalEndpoint
    let method: RelatedDigitalRequestMethod
    let timeoutInterval: TimeInterval
    let requestBody: Data?
    let queryItems: [URLQueryItem]?
    let headers: [String: String]
    let parse: (Data) -> A?
    let guid: String?
}

public enum RelatedDigitalError: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .parseError
        case 1:
            self = .noData
        case 2:
            let statusCode = try container.decode(Int.self, forKey: .associatedValue)
            self = .notOKStatusCode(statusCode: statusCode)
        case 3:
            let errorDescription = try container.decode(String.self, forKey: .associatedValue)
            self = .other(errorDescription: errorDescription)
        default:
            throw CodingError.unknownValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .parseError:
             try container.encode(0, forKey: .rawValue)
        case .noData:
            try container.encode(1, forKey: .rawValue)
        case .notOKStatusCode(let statusCode):
            try container.encode(2, forKey: .rawValue)
            try container.encode(statusCode, forKey: .associatedValue)
        case .other(let errorDescription):
            try container.encode(3, forKey: .rawValue)
            try container.encode(errorDescription, forKey: .associatedValue)
        }

    }

    enum Key: CodingKey {
        case rawValue
        case associatedValue
    }

    enum CodingError: Error {
        case unknownValue
    }

    case parseError
    case noData
    case notOKStatusCode(statusCode: Int)
    case other(errorDescription: String?)
}

struct RelatedDigitalBasePath {
    static var endpoints = [RelatedDigitalEndpoint: String]()

    // TO_DO: path parametresini kaldır
    static func buildURL(relatedDigitalEndpoint: RelatedDigitalEndpoint, queryItems: [URLQueryItem]?) -> URL? {
        guard let endpoint = endpoints[relatedDigitalEndpoint], let url = URL(string: endpoint) else {
            return nil
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        // components?.path = path
        components?.queryItems = queryItems
        return components?.url

    }

    static func getEndpoint(relatedDigitalEndpoint: RelatedDigitalEndpoint) -> String {
        return endpoints[relatedDigitalEndpoint] ?? ""
    }
}

class RelatedDigitalNetwork {

    class func apiRequest<A>(resource: RelatedDigitalResource<A>,
                             failure: @escaping (RelatedDigitalError, Data?, URLResponse?) -> Void,
                             success: @escaping (A, URLResponse?) -> Void) {
        guard let request = buildURLRequest(resource: resource) else {
            return
        }

        // TO_DO: burada cookie'leri düzgün handle edecek bir yöntem bul.
        URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            guard let httpResponse = response as? HTTPURLResponse else {

                if let hasError = error {
                    failure(.other(errorDescription: hasError.localizedDescription), data, response)
                } else {
                    failure(.noData, data, response)
                }
                return
            }

            // TO_DO: buraya 201'i de ekleyebiliriz, relatedDigital sunucuları 201(created) de dönebiliyor. 304(Not modified)
            guard httpResponse.statusCode == 200/*OK*/ else {
                failure(.notOKStatusCode(statusCode: httpResponse.statusCode), data, response)
                return
            }
            guard let responseData = data else {
                failure(.noData, data, response)
                return
            }
            guard let result = resource.parse(responseData) else {
                failure(.parseError, data, response)
                return
            }

            success(result, response)
        }.resume()
    }

    private class func buildURLRequest<A>(resource: RelatedDigitalResource<A>) -> URLRequest? {
        guard let url = RelatedDigitalBasePath.buildURL(relatedDigitalEndpoint: resource.endPoint,
                                                  queryItems: resource.queryItems) else {
            return nil
        }

        RelatedDigitalLogger.debug("Fetching URL")
        RelatedDigitalLogger.debug(url.absoluteURL)
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = resource.requestBody
        // TO_DO: timeoutInterval dışarıdan alınacak
        request.timeoutInterval = 60

        for (key, value) in resource.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request as URLRequest
    }

    class func buildResource<A>(endPoint: RelatedDigitalEndpoint,
                                method: RelatedDigitalRequestMethod,
                                timeoutInterval: TimeInterval,
                                requestBody: Data? = nil,
                                queryItems: [URLQueryItem]? = nil,
                                headers: [String: String],
                                parse: @escaping (Data) -> A?,
                                guid: String? = nil) -> RelatedDigitalResource<A> {
        return RelatedDigitalResource(endPoint: endPoint,
                                method: method,
                                timeoutInterval: timeoutInterval,
                                requestBody: requestBody,
                                queryItems: queryItems,
                                headers: headers,
                                parse: parse,
                                guid: guid)
    }

}