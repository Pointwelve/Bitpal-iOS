//
//  SearchModels.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

// MARK: - Search Response Models

struct CurrencySearchResponse: Codable {
    let results: [CurrencySearchResult]
    let status: String
    let message: String?
}

struct CurrencySearchResult: Codable {
    let id: String
    let name: String
    let symbol: String
    let description: String?
    let logo: String?
    let price: Double?
    let percentChange24h: Double?
    let marketCap: Double?
    let volume24h: Double?
    let rank: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "CoinName"
        case symbol = "Symbol"
        case description = "Description"
        case logo = "ImageUrl"
        case price = "PRICE"
        case percentChange24h = "CHANGEPCT24HOUR"
        case marketCap = "MKTCAP"
        case volume24h = "TOTALVOLUME24H"
        case rank = "SortOrder"
    }
}

struct ExchangeSearchResponse: Codable {
    let results: [ExchangeSearchResult]
    let status: String
    let message: String?
}

struct ExchangeSearchResult: Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let logo: String?
    let volume24h: Double?
    let url: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case slug = "InternalName"
        case description = "Description"
        case logo = "LogoUrl"
        case volume24h = "VOLUME24HOUR"
        case url = "Url"
        case country = "Country"
    }
}

struct NewsResponse: Codable {
    let data: [NewsItem]
    let status: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case status = "Type"
        case message = "Message"
    }
}

struct NewsItem: Codable {
    let id: String
    let title: String
    let body: String
    let tags: String
    let source: String
    let imageUrl: String?
    let url: String
    let publishedOn: Date
    let upvotes: Int
    let downvotes: Int
    let categories: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case tags
        case source = "source_info"
        case imageUrl = "imageurl"
        case url
        case publishedOn = "published_on"
        case upvotes
        case downvotes
        case categories
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        tags = try container.decode(String.self, forKey: .tags)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        url = try container.decode(String.self, forKey: .url)
        upvotes = try container.decodeIfPresent(Int.self, forKey: .upvotes) ?? 0
        downvotes = try container.decodeIfPresent(Int.self, forKey: .downvotes) ?? 0
        categories = try container.decode(String.self, forKey: .categories)
        
        // Handle source as nested object or string
        if let sourceInfo = try? container.decode([String: String].self, forKey: .source),
           let sourceName = sourceInfo["name"] {
            source = sourceName
        } else {
            source = try container.decode(String.self, forKey: .source)
        }
        
        // Handle publishedOn as timestamp
        let timestamp = try container.decode(TimeInterval.self, forKey: .publishedOn)
        publishedOn = Date(timeIntervalSince1970: timestamp)
    }
}