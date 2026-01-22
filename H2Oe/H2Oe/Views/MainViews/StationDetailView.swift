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
                geosphereSection
            }
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .navigationTitle("Details")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(Color.cyan.opacity(0.15), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: station.hzbnr) { //if hzbnr changes geosphere data is fetched
            await loadGeosphere()
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
                    Text("DBMSNR").font(.footnote).foregroundStyle(.primary)
                    Spacer()
                    Text("\(String(station.dbmsnr))").font(.footnote).foregroundStyle(.primary)
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

