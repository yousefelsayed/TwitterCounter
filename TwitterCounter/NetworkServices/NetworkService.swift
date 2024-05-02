//
//  NetworkService.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 10/09/2023.
//

import Foundation

typealias ResultCallback<T> = Result<T, NetworkError>

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
}

protocol NetworkService {
    
    func performRequest<T: Decodable>(endPoint: String, method: HTTPMethod, header: [String: String]) async throws -> Result<T, NetworkError> 
}
