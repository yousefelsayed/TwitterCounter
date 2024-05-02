//
//  Models.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 02/05/2024.
//

import Foundation

struct TweetContent: Codable {
    let text: String
}

struct TweetResponse: Codable {
    let data: TweetResponseData
}

struct TweetResponseData: Codable {
    let id, text: String
}
