//
//  Airline.swift
//  Enroute
//
//  Created by JT3 on 2020/09/17.
//  Copyright © 2020 JT. All rights reserved.
//

import Foundation
import CoreData

extension Airline: Comparable {
    public static func < (lhs: Airline, rhs: Airline) -> Bool {
        lhs.name < rhs.name
    }
    
    var code: String {
        get { code_! }
        set { code_ = newValue }
    }
    
    var name: String {
        get { name_ ?? "Unknown" }
        set { name_ = newValue }
    }
    
    var shortName: String {
        get { shortName_! }
        set { shortName_ = newValue }
    }
    
    var flights: Set<Flight> {
        get { (flights_ as? Set<Flight>) ?? [] }
        set { flights_ = newValue as NSSet}
    }
}

extension Airline {
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airline> {
        let request = NSFetchRequest<Airline>(entityName: "Airline")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
        return request
    }
}

extension Airline {
    var friendlyName: String {
        shortName_ ?? name
    }
}

extension Airline {
    static func withCode(_ code: String, in context: NSManagedObjectContext) -> Airline {
        // look up icao in Core Data
        let request = fetchRequest(NSPredicate(format: "code_ = %@", code))
        let airlines = (try? context.fetch(request)) ?? []
        
        if let airline = airlines.first {
            // if found, return it.
            return airline
        } else {
            // if not found, create one and fetch from FlightAware.
            let airline = Airline(context: context)
            airline.code = code
            AirlineInfoRequest.fetch(code) { airlineInfo in
                self.update(from: airlineInfo, context: context)
            }
            return airline
        }
    }
    
    static func update(from airlineInfo: AirlineInfo, context: NSManagedObjectContext) {
        if let code = airlineInfo.code {
            let airline = withCode(code, in: context)
            airline.name = airlineInfo.name
            airline.shortName = airlineInfo.shortname
            airline.objectWillChange.send()
            for flight in airline.flights {
                flight.objectWillChange.send()
            }
        }
    }

}
