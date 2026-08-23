//
//  ForecastStore.swift
//  H2Oe
//
//  Shared, observable forecast state. Loaded once on app open via a single
//  batch request for all live stations (so the API's per-IP rate limit is
//  never hit); the single-station path is only a fallback (e.g. a favourite
//  missing from the batch, retried when its detail view opens). Every failure
//  is exposed as `errorText` for the UI to show.
//

import DataProvider
import Foundation
import Observation

@MainActor
@Observable
final class ForecastStore {
    private(set) var byHzbnr: [Int: StationForecast] = [:]
    private(set) var issuedAt: Date?
    private(set) var isLoading = false
    private(set) var errorText: String?

    /// Batch-load forecasts for all given stations in ONE request (app open).
    func loadBatch(hzbnrs: [Int]) async {
        guard !hzbnrs.isEmpty, !isLoading else { return }
        isLoading = true
        errorText = nil

        let result: Result<BatchForecastResponse, ForecastError> = await withCheckedContinuation { cont in
            fetchForecastsBatch(hzbnrs: hzbnrs) { cont.resume(returning: $0) }
        }

        switch result {
        case .success(let batch):
            byHzbnr = batch.byHzbnr
            issuedAt = batch.issuedAt
        case .failure(let error):
            errorText = error.errorDescription
        }
        isLoading = false
    }

    /// Fallback for a single station (e.g. a favourite missing from the batch).
    /// Returns an error message on failure, nil on success.
    @discardableResult
    func loadSingle(hzbnr: Int) async -> String? {
        let result: Result<ForecastResponse, ForecastError> = await withCheckedContinuation { cont in
            fetchForecast(hzbnr: hzbnr) { cont.resume(returning: $0) }
        }

        switch result {
        case .success(let response):
            byHzbnr[hzbnr] = StationForecast(
                station: response.station,
                ok: true,
                cached: response.cached,
                predictions: response.predictions,
                error: nil
            )
            if issuedAt == nil { issuedAt = response.issuedAt }
            return nil
        case .failure(let error):
            return error.errorDescription
        }
    }

    func forecast(for hzbnr: Int) -> StationForecast? { byHzbnr[hzbnr] }

    /// Map a fetched forecast into the persistable value stored on a favourite.
    static func stored(from forecast: StationForecast, issuedAt: Date) -> StoredForecast? {
        guard let predictions = forecast.predictions, !predictions.isEmpty else { return nil }
        let points = predictions.map { prediction in
            StoredForecast.Point(
                horizonH: prediction.horizonH,
                qPred: prediction.qPred,
                floodFlags: prediction.hq?.mapValues { $0.flag }
            )
        }
        return StoredForecast(issuedAt: issuedAt, points: points)
    }
}
