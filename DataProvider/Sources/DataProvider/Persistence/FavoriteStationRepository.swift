import Foundation
import SwiftData


//repository for "DB-interactions"
public struct FavoriteStationRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Insert if missing, otherwise update.
    /// Only overwrites value/time if the new measurement is newer
    public func updateFavoriteStation(
        name: String,
        hzbnr: Int,
        unit: String,
        newValue: Double,
        lastTimeOfMeasurement: Date,
        isFavorite: Bool? = nil
    ) throws {
        //does hzbnr already exist?
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.hzbnr == hzbnr }
        )

        //gets station-info
        if let station = try context.fetch(descriptor).first {
            
            //delete 
            if isFavorite == false {
                            context.delete(station)
                            try context.save()
                            return
                        }
            
            // overwrite metadata
            station.name = name
            station.unit = unit
            if let isFavorite { station.isFavorite = isFavorite }

            // overwrite measurement (only if newer)
            if lastTimeOfMeasurement >= station.lastTimeOfMeasurement {
                station.value.append(newValue)
                station.lastTimeOfMeasurement = lastTimeOfMeasurement
            }
        } else {
            //no station found -> new entry!
            let station = FavoriteStation(
                name: name,
                hzbnr: hzbnr,
                unit: unit,
                isFavorite: isFavorite ?? true,
                initialValue: newValue,
                lastTimeOfMeasurement: lastTimeOfMeasurement
            )
            context.insert(station)  //!!!
        }

        try context.save() //now it writes!!!!
    }
}
