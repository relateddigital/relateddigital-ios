//
//  WebService.swift
//  webServiceModel
//
//  Created by Orhun Akmil on 16.12.2021.
//

import Foundation


class WebService {
    static var model = WebService()
    private var urlSession: URLSession = .shared
 
    enum requestType : String {
        case POST = "POST"
        case GET = "GET"
        
    }
    
    
    func sendRequest(urlString:String,requestType:requestType,JSONBody:Data,completionHandler: @escaping (_ response:Data?,_ err:String?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            completionHandler(nil, "")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = requestType.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = JSONBody
        
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            
            if let requestError = error {
                completionHandler(nil, requestError.localizedDescription)
                return
            }
            if let data = data {
                completionHandler(data,nil)
            }
        }
        dataTask.resume()
    }
}



protocol relatedDigitalRequestModel:Codable {
    func getJSONData() -> Data
}

protocol relatedDigitalResponseModel:Decodable {
    func getModel(jsonData:Data) -> Any
}
