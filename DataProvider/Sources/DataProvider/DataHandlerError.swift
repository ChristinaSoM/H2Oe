//
//  DataHandlerError.swift
//  DataProvider
//
//  Created by Christina Moser on 19.12.25.
//

import Foundation
import SwiftData

public enum DataHandlerError: Error {
    case itemNotFound(id: PersistentIdentifier)
}
    
extension DataHandlerError {
    var errorInfo: String {
        switch self {
        case .itemNotFound(let id):
            return "Item not found (id: \(id))."
        }
    }
}
