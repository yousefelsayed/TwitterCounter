//
//  URLSessionNetworkService.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 10/09/2023.
//


import Foundation

class URLSessionNetworkService: NetworkService {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func performRequest<T: Decodable>(endPoint: String, method: HTTPMethod, header: [String:String] = [:]) async throws -> Result<T, NetworkError> {
        
        let request = try EndPoint.shared.createCustomURL(path: endPoint, method: method, header: header)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(with: .failure(NetworkError.requestFailed(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    continuation.resume(with: .failure(NetworkError.invalidResponse))
                    return
                }
                
                guard let data1 = data else {
                    continuation.resume(with: .failure(NetworkError.invalidResponse))
                    return
                }
                
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data1)
                    continuation.resume(returning: .success(decodedData))
                } catch {
                    continuation.resume(with: .failure(NetworkError.requestFailed(error)))
                }
            }
            task.resume()
        }
    }
}
