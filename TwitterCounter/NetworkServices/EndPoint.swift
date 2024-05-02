//
//  APIEndPoint.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 10/09/2023.
//

import Foundation

class EndPoint {
    static let shared = EndPoint()
    
    private init() {}
    
    static let baseURL = "https://api.twitter.com/"
    
    func createCustomURL(path: String, method: HTTPMethod, header: [String:String]) throws ->  URLRequest {
        let components = URLComponents(string: EndPoint.baseURL + path)
        
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = header
        
        return request
    }
}

