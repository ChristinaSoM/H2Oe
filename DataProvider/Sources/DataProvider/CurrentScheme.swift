//
//  CurrentScheme.swift
//  DataProvider
//
//  Created by Christina Moser on 25.11.25.
//
//Reference: https://dev.to/fatbobman/practical-swiftdata-building-swiftui-applications-with-modern-approaches-4b7j

import SwiftData

public typealias CurrentScheme = SchemaV1

public enum SchemaV1: VersionedSchema {
  public static var versionIdentifier: Schema.Version {
    .init(1, 0, 0)
  }

  public static var models: [any PersistentModel.Type] {
    [Item.self]
  }
}
