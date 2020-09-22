//
//  Airport.swift
//  Enroute
//
//  Created by JT3 on 2020/09/17.
//  Copyright © 2020 JT. All rights reserved.
//

import CoreData
import Combine


extension Airport {
    static func withICAO(_ icao: String, context: NSManagedObjectContext) -> Airport {
        // look up icao in Core Data
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.predicate = NSPredicate(format: "icao = %@", icao)
        request.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        
        let airports = (try? context.fetch(request)) ?? []
        
        if let airport = airports.first {
            // if found, return it.
            return airport
        } else {
            // if not found, create one and fetch from FlightAware.
            let airport = Airport(context: context)
            airport.icao = icao
            AirportInfoRequest.fetch(icao) { airportInfo in
                self.update(from: airportInfo, context: context)
            }
            return airport
        }
    }
    
    static func update(from info: AirportInfo, context: NSManagedObjectContext) {
        if let icao = info.icao {
            let airport = Airport.withICAO(icao, context: context)
            airport.latitude = info.latitude
            airport.longitude = info.longitude
            airport.location = info.location
            airport.timezone = info.timezone
            airport.name = info.name
            
            airport.objectWillChange.send()
            airport.flightsTo.forEach { $0.objectWillChange.send() }
            airport.flightsFrom.forEach { $0.objectWillChange.send() }

            try? context.save()
        }
    }
    
    private var flightsTo: Set<Flight> {
        get { (flightsTo_ as? Set<Flight>) ?? [] }
        set { flightsTo_ = newValue as NSSet}
    }
    private var flightsFrom: Set<Flight> {
        get { (flightsFrom_ as? Set<Flight>) ?? [] }
        set { flightsFrom_ = newValue as NSSet}
    }
}

extension Airport: Comparable {
    var icao: String {
        get { icao_! }
        set { icao_ = newValue }
    }
    
    var friendlyName: String {
        let friendly = AirportInfo.friendlyName(name: self.name ?? "", location: self.location ?? "")
        return friendly.isEmpty ? icao : friendly
    }
    
    public var id: String { icao }
    
    public static func < (lhs: Airport, rhs: Airport) -> Bool {
        lhs.friendlyName < rhs.friendlyName
    }
}
