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
        let request = Airport.fetchRequest(NSPredicate(format: "icao_ = %@", icao))
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

extension Airport {
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        return request
    }
}

extension Airport {
    private static var flightAwareRequest: EnrouteRequest!
    private static var flightAwareRequestCancellable: AnyCancellable?
    func fetchIncomingFlights() {
        Self.flightAwareRequest?.stopFetching()
        if let context = managedObjectContext {
            Airport.flightAwareRequest = EnrouteRequest.create(airport: self.icao, howMany: 120)
            Airport.flightAwareRequest?.fetch()
            Self.flightAwareRequestCancellable = Airport.flightAwareRequest?.results.sink { faflights in
                for faflight in faflights {
                    Flight.update(from: faflight, in: context)
                }
                do {
                    try context.save()
                } catch {
                    print("Couldn't save flight update to CoreData: \(error.localizedDescription)")
                }
            }
        }
    }
}
