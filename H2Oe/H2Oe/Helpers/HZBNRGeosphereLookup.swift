//
//  z.swift
//  H2Oe
//
//  Created by Christina Moser on 21.01.26.
//

import Foundation

enum MappingLookupError: Error {
    case fileNotFound
    case invalidFormat
}


/// csv contains: hzbnr,geosphere_id
func getGeosphereId(hzbnr: Int) throws -> Int? {
    guard let url = Bundle.main.url(forResource: "qstations_to_nearest_geosphere", withExtension: "csv") else {
        throw MappingLookupError.fileNotFound
    }

    let data = try Data(contentsOf: url)
    let text = String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .isoLatin1)
        ?? ""

    let lines = text.split(whereSeparator: \.isNewline).map(String.init)
    guard !lines.isEmpty else { return nil }

    let startIndex = lines.first?.lowercased().contains("hzbnr") == true ? 1 : 0

    for line in lines[startIndex...] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { continue }

        let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { continue }

        if let h = Int(parts[0]), h == hzbnr {
            return Int(parts[1])
        }
    }

    return nil
}
