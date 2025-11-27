//
//  NetworkingError.swift
//  Login Screen Exercise
//
//  Created by Christina Moser on 17.10.25.
//

import Foundation

enum NetworkingError: Error, Sendable {
    case dictionarySerializationError                                              // yes
    case invalidEmailError  // 400 - "message": "INVALID_EMAIL",                   // yes
    case emailNotFoundError  // 400 "message": "INVALID_LOGIN_CREDENTIALS",        // YES
    case correctEmailWrongPasswordError  // 400 INVALID_LOGIN_CREDENTIALS          // YES
    case invalidLoginCredentialsError  // 400 INVALID_LOGIN_CREDENTIALS (because of emailNotFoundError and/or correctEmailWrongPasswordError)
    case networkOfflineError                                                      // yes
    case unexpectedResponseFormatError                                            // yes
    case nonSuccessfulResponseCodeError(statusCode: Int)                          // yes
    case unexpectedError                                                          // yes
    // additional country response errors
    case permissionDeniedError   // 403 PERMISSION_DENIED  (in case of wrong or missing ID Token / unauthorized )
    case missingIDToken
    
}


extension NetworkingError {
    var userMessage: String {
        switch self {
        case .dictionarySerializationError:
            return "Dictionary Serialization Error: Failed to create the request."
        case .invalidEmailError:
            return "Invalid Email: Please enter a valid email e.g. user@example.com."
        case .emailNotFoundError:
            return "Email Not Found: This email is not registered."
        case .correctEmailWrongPasswordError:
            return "Wrong password. Please try again."
        case .invalidLoginCredentialsError:
            return "Invalid Login Credentials: Wrong email and/or password. Please try again."
        case .networkOfflineError:
            return "No internet connection."
        case .unexpectedResponseFormatError:
            return "Unexpected response format. Please try again."
        case .nonSuccessfulResponseCodeError(let code):
            return "Error (HTTP \(code)). Please try again."
        case .unexpectedError:
            return "Unexpected error. Please try again."
        case .missingIDToken:
            return "Unauthorized. Please log in again."
        case .permissionDeniedError:
            return "Permission denied."
        }
    }
}




