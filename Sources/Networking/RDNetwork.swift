//
//  RDNetwork.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 20.01.2022.
//

import Foundation

enum RDRequestMethod: String {
    case get
    case post
}

enum RDEndpoint {
    case logger
    case realtime
    case target
    case action
    case geofence
    case mobile
    case subsjson
    case promotion
    case remote
    case search
    case logConfig
    
    case spinToWinJs
    case giftCatchJs
    case findToWinJs
    case giftBoxJs
    case chooseFavoriteJs
    case jackpotJs
    case clawMachineJs


}

struct RDResource<A> {
    let endPoint: RDEndpoint
    let method: RDRequestMethod
    let requestBody: Data?
    let queryItems: [URLQueryItem]?
    let headers: Properties
    let parse: (Data) -> A?
    let guid: String?
}

public enum RDError: Codable {
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

struct RDBasePath {
    static var endpoints = [RDEndpoint: String]()

        static func buildURL(rdEndpoint: RDEndpoint, queryItems: [URLQueryItem]?) -> URL? {
             guard let endpoint = endpoints[rdEndpoint] else {
                 RDLogger.error("Endpoint not defined for \(rdEndpoint)")
                 return nil
             }
             guard var urlComponents = URLComponents(string: endpoint) else {
                  RDLogger.error("Invalid base URL for endpoint \(rdEndpoint)")
                  return nil
             }
            urlComponents.queryItems = queryItems
            return urlComponents.url
        }

        static func getEndpoint(rdEndpoint: RDEndpoint) -> String {
            return endpoints[rdEndpoint] ?? ""
        }
}

class RDNetwork {
    
    class func apiRequest<A>(resource: RDResource<A>, failure: @escaping (RDError, Data?, URLResponse?) -> Void, success: @escaping (A, URLResponse?) -> Void) {
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
            
            // TO_DO: buraya 201'i de ekleyebiliriz, visilabs sunucuları 201(created) de dönebiliyor. 304(Not modified)
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
    
    private class func buildURLRequest<A>(resource: RDResource<A>) -> URLRequest? {
        
        guard let url = RDBasePath.buildURL(rdEndpoint: resource.endPoint, queryItems: resource.queryItems) else {
            return nil
        }
        
        RDLogger.debug("Fetching URL: \(url.absoluteURL)")
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = resource.requestBody
        request.timeoutInterval = RelatedDigital.rdProfile.requestTimeoutInterval
        
        for (key, value) in resource.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request as URLRequest
    }
    
    class func buildResource<A>(endPoint: RDEndpoint, method: RDRequestMethod, requestBody: Data? = nil, queryItems: [URLQueryItem]? = nil, headers: Properties, parse: @escaping (Data) -> A?, guid: String? = nil) -> RDResource<A> {
        return RDResource(endPoint: endPoint, method: method, requestBody: requestBody, queryItems: queryItems, headers: headers, parse: parse, guid: guid)
    }
    
}
