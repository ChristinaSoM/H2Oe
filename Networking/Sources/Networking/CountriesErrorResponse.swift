//
//  ContriesErrorResponse.swift
//  Login Screen Exercise
//
//  Created by Christina Moser on 27.10.25.
//

import Foundation

struct CountriesErrorResponse: Codable {
    // response is a dictionary '"error":' that contains:
    let code: Int
    let message: String
    let status: String
    
    private enum DictCodingKeys: String, CodingKey {
        case error
    }
    
    enum ErrorCodingKeys: String, CodingKey {
        case code
        case message
        case status
    }
    
        
    init(from decoder: Decoder) throws {
        let dictContainer = try decoder.container(keyedBy: DictCodingKeys.self)
        let errorContainer = try dictContainer.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
        
        code = try errorContainer.decode(Int.self, forKey: .code)
        message = try errorContainer.decode(String.self, forKey: .message)
        status = try errorContainer.decode(String.self, forKey: .status)
    }
}
