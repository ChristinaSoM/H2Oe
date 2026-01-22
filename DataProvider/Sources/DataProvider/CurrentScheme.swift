//
//  CurrentScheme.swift
//  DataProvider
//
//  Created by Christina Moser on 25.11.25.
//
//Reference: https://dev.to/fatbobman/practical-swiftdata-building-swiftui-applications-with-modern-approaches-4b7j

import SwiftData

public typealias CurrentScheme = SchemaV2

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }
    
    public static var models: [any PersistentModel.Type] {
        [FavoriteStation.self]
    }
}


public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(2, 0, 0)
    }
    
    public static var models: [any PersistentModel.Type] {
        [FavoriteStation.self]
    }
}
