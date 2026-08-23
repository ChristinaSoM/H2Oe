//
//  DataProviderTests.swift
//  DataProvider
//
//  Created by Christina Moser on 25.11.25.
//

import Foundation
import Testing
import SwiftData
@testable import DataProvider


struct SwiftDataContainerForTest  {
  static func temp(_ name: String, delete: Bool = true) throws -> ModelContainer {
    let url = URL.temporaryDirectory.appending(component: name)
    if delete, FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }
    let schema = Schema(CurrentScheme.models)
    let configuration = ModelConfiguration(url: url)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return container
  }
}


@MainActor
struct DataProviderTests {

    // MARK: - Insert

    /// Contract 1: an unknown hzbnr inserts exactly one row carrying the supplied
    /// fields, seeds `value` with `[newValue]`, and defaults `isFavorite` to true
    /// when the argument is nil.
    @Test
    func insertsNewStationWhenHzbnrMissing() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        let measured = Date(timeIntervalSince1970: 1_000)
        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 12.5,
            lastTimeOfMeasurement: measured
        )

        let rows = try container.mainContext.fetch(FetchDescriptor<FavoriteStation>())
        #expect(rows.count == 1)

        let station = try #require(rows.first)
        #expect(station.hzbnr == 42)
        #expect(station.name == "Wien")
        #expect(station.unit == "m³/s")
        #expect(station.value == [12.5])
        #expect(station.lastTimeOfMeasurement == measured)
        #expect(station.isFavorite == true)
    }

    /// Contract 5 (edge): an ABSENT hzbnr called with `isFavorite: false` must still
    /// INSERT a single row — the delete branch only fires when a row already exists —
    /// and that inserted row must be non-favorite.
    @Test
    func insertsNonFavoriteRowWhenAbsentAndIsFavoriteFalse() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        try repo.updateFavoriteStation(
            name: "Graz",
            hzbnr: 7,
            unit: "cm",
            newValue: 3.0,
            lastTimeOfMeasurement: Date(timeIntervalSince1970: 500),
            isFavorite: false
        )

        let rows = try container.mainContext.fetch(FetchDescriptor<FavoriteStation>())
        #expect(rows.count == 1)

        let station = try #require(rows.first)
        #expect(station.hzbnr == 7)
        #expect(station.isFavorite == false)
        #expect(station.value == [3.0])
    }

    // MARK: - Update

    /// Contract 2: a second call for the same hzbnr with a newer measurement updates
    /// in place (no duplicate row), overwrites name/unit, APPENDS the new value, and
    /// advances the timestamp.
    @Test
    func updatesInPlaceAndAppendsWhenMeasurementNewer() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        let t1 = Date(timeIntervalSince1970: 1_000)
        let t2 = Date(timeIntervalSince1970: 2_000)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 10.0,
            lastTimeOfMeasurement: t1
        )
        try repo.updateFavoriteStation(
            name: "Wien-Nord",
            hzbnr: 42,
            unit: "cm",
            newValue: 11.0,
            lastTimeOfMeasurement: t2
        )

        let rows = try container.mainContext.fetch(FetchDescriptor<FavoriteStation>())
        #expect(rows.count == 1)

        let station = try #require(rows.first)
        #expect(station.name == "Wien-Nord")
        #expect(station.unit == "cm")
        #expect(station.value == [10.0, 11.0])
        #expect(station.lastTimeOfMeasurement == t2)
    }

    /// Contract 2 boundary: an EQUAL timestamp still counts as newer-or-equal, so the
    /// value is appended. Pins the `>=` gate against a `>` regression.
    @Test
    func appendsWhenMeasurementTimestampEqual() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        let t = Date(timeIntervalSince1970: 1_000)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 10.0,
            lastTimeOfMeasurement: t
        )
        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 11.0,
            lastTimeOfMeasurement: t
        )

        let station = try #require(
            try container.mainContext.fetch(FetchDescriptor<FavoriteStation>()).first
        )
        #expect(station.value == [10.0, 11.0])
        #expect(station.lastTimeOfMeasurement == t)
    }

    /// Contract 3: a strictly OLDER measurement must NOT append and must NOT rewind the
    /// timestamp, even though metadata (name/unit) is still overwritten.
    @Test
    func doesNotAppendOrRewindWhenMeasurementOlder() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        let newer = Date(timeIntervalSince1970: 2_000)
        let older = Date(timeIntervalSince1970: 1_000)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 10.0,
            lastTimeOfMeasurement: newer
        )
        try repo.updateFavoriteStation(
            name: "Wien-Alt",
            hzbnr: 42,
            unit: "cm",
            newValue: 99.0,
            lastTimeOfMeasurement: older
        )

        let station = try #require(
            try container.mainContext.fetch(FetchDescriptor<FavoriteStation>()).first
        )
        // measurement gate held: no append, no rewind
        #expect(station.value == [10.0])
        #expect(station.lastTimeOfMeasurement == newer)
        // metadata still overwritten
        #expect(station.name == "Wien-Alt")
        #expect(station.unit == "cm")
    }

    // MARK: - Delete

    /// Contract 4: `isFavorite: false` on an EXISTING row deletes it.
    @Test
    func deletesExistingRowWhenIsFavoriteFalse() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 10.0,
            lastTimeOfMeasurement: Date(timeIntervalSince1970: 1_000),
            isFavorite: true
        )
        #expect(try container.mainContext.fetch(FetchDescriptor<FavoriteStation>()).count == 1)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 11.0,
            lastTimeOfMeasurement: Date(timeIntervalSince1970: 2_000),
            isFavorite: false
        )

        let rows = try container.mainContext.fetch(FetchDescriptor<FavoriteStation>())
        #expect(rows.count == 0)
    }

    // MARK: - Forecast

    /// Contract 6: a forecast attached to an existing favourite survives the SwiftData
    /// Codable round-trip — issuedAt, point ordering, scalar fields, and the optional
    /// floodFlags dictionary all come back intact after a fresh fetch.
    @Test
    func forecastSurvivesCodableRoundTrip() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        try repo.updateFavoriteStation(
            name: "Wien",
            hzbnr: 42,
            unit: "m³/s",
            newValue: 10.0,
            lastTimeOfMeasurement: Date(timeIntervalSince1970: 1_000)
        )

        let issued = Date(timeIntervalSince1970: 1_700_000_000)
        let forecast = StoredForecast(
            issuedAt: issued,
            points: [
                StoredForecast.Point(
                    horizonH: 6,
                    qPred: 12.5,
                    floodFlags: ["HQ1": true, "HQ5": false]
                ),
                StoredForecast.Point(horizonH: 12, qPred: 20.0, floodFlags: nil),
            ]
        )
        try repo.updateFavoriteForecast(hzbnr: 42, forecast: forecast)

        let station = try #require(
            try container.mainContext.fetch(FetchDescriptor<FavoriteStation>()).first
        )
        let stored = try #require(station.forecast)

        #expect(stored.issuedAt == issued)
        #expect(stored.points.count == 2)

        let first = try #require(stored.points.first)
        #expect(first.horizonH == 6)
        #expect(first.qPred == 12.5)
        #expect(first.floodFlags == ["HQ1": true, "HQ5": false])

        let second = stored.points[1]
        #expect(second.horizonH == 12)
        #expect(second.qPred == 20.0)
        #expect(second.floodFlags == nil)
    }

    /// Contract 7: `updateFavoriteForecast` for an absent hzbnr is a silent no-op —
    /// it neither throws nor inserts a row.
    @Test
    func forecastUpdateIsNoOpWhenStationAbsent() throws {
        let container = try SwiftDataContainerForTest.temp(#function)
        let repo = FavoriteStationRepository(context: container.mainContext)

        let forecast = StoredForecast(
            issuedAt: Date(timeIntervalSince1970: 1_700_000_000),
            points: [StoredForecast.Point(horizonH: 6, qPred: 1.0)]
        )
        try repo.updateFavoriteForecast(hzbnr: 999, forecast: forecast)

        let rows = try container.mainContext.fetch(FetchDescriptor<FavoriteStation>())
        #expect(rows.count == 0)
    }
}
