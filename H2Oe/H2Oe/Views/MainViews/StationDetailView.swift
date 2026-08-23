import SwiftUI
import SwiftData
import DataProvider
import Charts

struct StationDetailView: View {
    
    let station: StationDetails
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var geosphereId: Int?
    @State private var geosphereData: GeosphereFeatureCollection?
    @Environment(ForecastStore.self) private var forecastStore: ForecastStore?
    @State private var forecastError: String?
    @State private var forecastLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                HStack(alignment: .firstTextBaseline) {
                    Text(station.name)
                        .font(.title)
                        .bold()
                        .padding(.bottom, 4)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    FavoriteButton(
                        name: station.name,
                        hzbnr: station.hzbnr,
                        unit: station.unit,
                        value: station.value,
                        lastTimeOfMeasurement: station.timeOfMeasurement,
                    )
                }
                .padding(.top, 6)
                .padding(.horizontal)
                
                qHeader
                stationInfoCard
                forecastSection
                geosphereSection
            }
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .navigationTitle("Details")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(Color.cyan.opacity(0.15), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: station.hzbnr) { // load forecast + weather concurrently so a slow
                                   // forecast server never blocks the GeoSphere charts
            async let forecast: Void = loadForecastIfNeeded()
            async let geosphere: Void = loadGeosphere()
            _ = await (forecast, geosphere)
        }
    }

    
    @MainActor
    private func loadGeosphere() async {
        if isLoading { return }
        
        isLoading = true
        errorMessage = nil
        geosphereData = nil
        geosphereId = nil
        
        do {
            let geoId = try getGeosphereId(hzbnr: station.hzbnr)
            geosphereId = geoId
            
            guard let geoId else {
                errorMessage = "No Geosphere mapping found for HZBNR \(station.hzbnr)."
                isLoading = false
                return
            }
            
            // define parameters for fetching
            let start = Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: Date())!
            
            let result: Result<GeosphereFeatureCollection, Error> = await withCheckedContinuation { cont in
                fetchHistoricalGeosphereStations(stationIds: [geoId], start: start) { res in
                    cont.resume(returning: res)
                }
            }
            
            switch result {
            case .success(let collection):
                geosphereData = collection
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    
    private var qHeader: some View {
        HStack {
            Text("Flow rate (Q)")
                .font(.title2)
                .bold()
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    
    
    private var stationInfoCard: some View {
        infoCard {
            VStack(alignment: .leading, spacing: 10) {
                
                Text("\(station.value, specifier: "%.2f") \(station.unit)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack {
                    Text("Timestamp").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text(station.timeOfMeasurement.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("HZBNR").font(.footnote).foregroundStyle(.primary)
                    Spacer()
                    Text("\(String(station.hzbnr))").font(.footnote).foregroundStyle(.primary)
                }
                
                Divider().padding(.vertical, 2)
                
                if let service = station.hydroService {
                    HStack {
                        Text("Hydro service").font(.footnote).foregroundStyle(.primary)
                        Spacer()
                        Text(service).font(.footnote).foregroundStyle(.primary)
                    }
                }
                
                HStack {
                    Text("Waterbody").font(.footnote).foregroundStyle(.primary)
                    Spacer()
                    Text(station.waterBody).font(.footnote).foregroundStyle(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var geosphereSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Meteorological values")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading weather data…")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                
            } else if let collection = geosphereData,
                      let feature = collection.features.first {
                
                if let geoId = geosphereId {
                    Text("Geosphere station: \(String(geoId))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                let keys = ["ff","p","rf","rr","rrm","sh","so","tb10","tb20","tl"]
                
                //creates view only if it is required -> loads content lazy 
                LazyVStack(spacing: 12) {
                    ForEach(keys, id: \.self) { key in
                        let points = feature.seriesPoints(for: key, timestamps: collection.timestamps)
                        let latestPair = feature.latestValueAndTime(for: key, timestamps: collection.timestamps)
                        
                        GeosphereParameterCard(
                            title: feature.displayNameEN(for: key),
                            unit: feature.unit(for: key) ?? "",
                            latestValue: latestPair?.value,
                            latestTime: latestPair?.time,
                            points: points
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                
            } else {
                Text("No Geosphere data returned.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Forecast")
                    .font(.title2)
                    .bold()
                Spacer()
                FloodWarningBadge(forecast: forecastStore?.forecast(for: station.hzbnr),
                                  showsWhenClear: true)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            AIGeneratedNote()
                .padding(.horizontal)

            if forecastLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading forecast…")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

            } else if let forecastError {
                Text(forecastError)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)

            } else if let store = forecastStore,
                      let forecast = store.forecast(for: station.hzbnr),
                      forecast.ok, let predictions = forecast.predictions, !predictions.isEmpty {
                let sorted = predictions.sorted { $0.horizonH < $1.horizonH }

                forecastSubHeader("Flow rate (Q)")
                infoCard {
                    ForEach(sorted) { prediction in
                        HStack(alignment: .firstTextBaseline) {
                            Text(horizonLabel(prediction.horizonH))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f m³/s", prediction.qPred))
                                .font(.body.monospacedDigit())
                        }
                        if prediction.id != sorted.last?.id { Divider() }
                    }
                }

                forecastSubHeader("Flood level (HQ)")
                infoCard {
                    ForEach(sorted) { prediction in
                        floodRow(for: prediction)
                        if prediction.id != sorted.last?.id { Divider() }
                    }
                }

            } else if let store = forecastStore,
                      let forecast = store.forecast(for: station.hzbnr), !forecast.ok {
                Text(forecast.error ?? "No forecast available for this station.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)

            } else {
                Text("No forecast available for this station.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func forecastSubHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 2)
    }

    @ViewBuilder
    private func floodRow(for prediction: ForecastPrediction) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(horizonLabel(prediction.horizonH))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let hq = prediction.hq {
                let exceeded = hq.filter { $0.value.flag }.keys.sorted()
                let level = hq
                    .compactMap { $0.value.flag ? FloodWarning.returnPeriod(fromKey: $0.key) : nil }
                    .filter { $0 >= 5 }
                    .map(FloodWarningLevel.forReturnPeriod)
                    .max() ?? .none
                if level != .none {
                    Image(systemName: level.symbolName)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                Text(exceeded.isEmpty ? "No exceedance" : exceeded.joined(separator: ", "))
                    .font(.subheadline)
                    .bold(level != .none)
                    .foregroundStyle(level == .none ? Color.secondary : level.tint)
            } else {
                Text("No flood data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func horizonLabel(_ horizon: Int) -> String {
        horizon == 0 ? "Now" : "+\(horizon) h"
    }

    /// The app-open batch usually already holds this station; fetch a single
    /// station only as a fallback (e.g. a favourite missing from the batch).
    @MainActor
    private func loadForecastIfNeeded() async {
        guard let store = forecastStore else { return }
        guard store.forecast(for: station.hzbnr) == nil else { return }
        forecastLoading = true
        forecastError = nil
        forecastError = await store.loadSingle(hzbnr: station.hzbnr)
        forecastLoading = false
    }
    
    
    // accepts any view content and displays it uniformly as a “card” (padding, background, border).
    private func infoCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
            .padding(.horizontal)
    }
}

