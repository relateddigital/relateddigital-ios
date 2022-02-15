//
//  PushAPI.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 10.02.2022.
//

import Foundation

protocol PushResponseProtocol: Decodable {}
class PushResponse: PushResponseProtocol {}

public enum PushAPIError: Error {
    case connectionFailed
    case other(String)
}

protocol PushAPIProtocol {
    func request<R: PushRequestProtocol,
                 T: PushResponseProtocol>(requestModel: R,
                                        retry: Int,
                                        completion: @escaping (Result<T?, PushAPIError>) -> Void)
}

class PushAPI: PushAPIProtocol {
    
    private var urlSession: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.httpMaximumConnectionsPerHost = 3
        return URLSession.init(configuration: configuration)
    }
    
    func request<R: PushRequestProtocol,
                 T: PushResponseProtocol>(requestModel: R,
                                        retry: Int,
                                        completion: @escaping (Result<T?, PushAPIError>) -> Void) {
        
        guard let request = setupUrlRequest(requestModel) else {return}
        
        URLSession.shared.dataTask(with: request) { [weak self, retry] data, response, connectionError in
            if connectionError == nil {
                let remoteResponse = response as? HTTPURLResponse
                DispatchQueue.main.async {
                    if connectionError == nil &&
                        (remoteResponse?.statusCode == 200 || remoteResponse?.statusCode == 201) {
                        if let remoteResponse = remoteResponse {
                            PushLog.success("Server response success : \(remoteResponse.statusCode)")
                        }
                        var responseData: T? = nil
                        if let data = data {
                            responseData =  try? JSONDecoder().decode(T.self, from: data)
                        }
                        completion(.success(responseData))
                    } else {
                        PushLog.error("Server response with failure : \(String(describing: remoteResponse))")
                        if retry > 0 {
                            self?.request(requestModel: requestModel, retry: retry - 1, completion: completion)
                            
                        } else {
                            completion(.failure(PushAPIError.connectionFailed))
                        }
                    }
                }
            } else {
                guard let connectionError = connectionError else {return}
                PushLog.error("Connection error \(connectionError)")
                if retry > 0 {
                    self?.request(requestModel: requestModel, retry: retry - 1, completion: completion)
                } else {
                    completion( .failure(PushAPIError.connectionFailed))
                }
            }
        }.resume()
    }
    
    func setupUrlRequest<R: PushRequestProtocol>(_ requestModel: R) -> URLRequest? {
        let urlString = "https://\(requestModel.subdomain)\(requestModel.prodBaseUrl)/\(requestModel.path)"
        guard let url = URL.init(string: urlString) else {
            PushLog.info("URL couldn't be initialized")
            return nil
        }
        let userAgent = Push.shared?.userAgent
        var request = URLRequest.init(url: url)
        request.httpMethod = requestModel.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue(userAgent, forHTTPHeaderField: PushKey.userAgent)
        request.timeoutInterval = TimeInterval(PushKey.timeoutInterval)
        
        if requestModel.method == "POST" || requestModel.method == "PUT" {
            request.httpBody = try? JSONEncoder().encode(requestModel)
        }
        
        if let httpBody = request.httpBody {
            PushLog.info("""
                Request to \(url) with body
                \(String(data: httpBody, encoding: String.Encoding.utf8) ?? "")
                """)
        }
        return request
    }
}
