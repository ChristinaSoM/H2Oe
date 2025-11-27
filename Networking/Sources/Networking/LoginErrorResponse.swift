//
//  FirebaseResponseError.swift
//  Login Screen Exercise
//
//  Created by Christina Moser on 17.10.25.
//

import Foundation

// response contains an errors array:
struct ErrorDetail: Codable {
    let message: String
    let domain: String
    let reason: String
}

struct LoginErrorResponse: Codable {
    // response is a dictionary '"error":' that contains:
    let code: Int
    let message: String
    let errors: [ErrorDetail]
    
    private enum DictCodingKeys: String, CodingKey {
        case error
    }
            
    enum ErrorCodingKeys: String, CodingKey {
        case code
        case message
        case errors
    }
        
    init(from decoder: Decoder) throws {
        let dictContainer = try decoder.container(keyedBy: DictCodingKeys.self)
        let errorContainer = try dictContainer.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
        
        code = try errorContainer.decode(Int.self, forKey: .code)
        message = try errorContainer.decode(String.self, forKey: .message)
        errors = try errorContainer.decode([ErrorDetail].self, forKey: .errors)
    }
}
