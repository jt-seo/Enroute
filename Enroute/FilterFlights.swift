//
//  FilterFlights.swift
//  Enroute
//
//  Created by CS193p Instructor on 5/12/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import MapKit

struct FilterFlights: View {
//    @FetchRequest var allAirports: FetchedResults<Airport>
//    @FetchRequest var allAirlines: FetchedResults<Airline>
    @FetchRequest(fetchRequest: Airport.fetchRequest(.all)) var allAirports: FetchedResults<Airport>
    @FetchRequest(fetchRequest: Airline.fetchRequest(.all)) var allAirlines: FetchedResults<Airline>

    @Binding var flightSearch: FlightSearch
    @Binding var isPresented: Bool
    
    @State private var draft: FlightSearch
    
    init(flightSearch: Binding<FlightSearch>, isPresented: Binding<Bool>) {
        _flightSearch = flightSearch
        _isPresented = isPresented
        _draft = State(wrappedValue: flightSearch.wrappedValue)
        
//        _allAirports = FetchRequest(fetchRequest: Airport.fetchRequest(.all))
//        _allAirlines = FetchRequest(fetchRequest: Airline.fetchRequest(.all))
    }
    
    var destination: Binding<MKAnnotation?> {
        Binding<MKAnnotation?>(
            get: { self.draft.destination },
            set: { annotation in
                if let airport = annotation as? Airport {
                    self.draft.destination = airport
                }
            }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Destination", selection: $draft.destination) {
                        ForEach (allAirports.sorted(), id: \.icao) { airport in
                            Text(airport.friendlyName).tag(airport)
                        }
                    }
                    MapView(annotations: allAirports.sorted(), selection: destination)
                        .frame(minHeight: 400)
                }
                Section {
                    Picker("Origin", selection: $draft.origin) {
                        Text("Any").tag(Airport?.none)
                        ForEach (allAirports.sorted(), id: \.icao) { (airport: Airport?) in
                            Text("\(airport?.friendlyName ?? "Empty")").tag(airport)
                        }
                    }
                    Picker("Airlines", selection: $draft.airline) {
                        Text("Any").tag(Airline?.none)
                        ForEach (allAirlines, id: \.code) { (airline: Airline?) in
                            Text("\(airline?.friendlyName ?? "Empty")").tag(airline)
                        }
                    }
                    Toggle(isOn: $draft.inTheAir) {
                        Text("Is on the air")
                    }
                }
            }
            .navigationBarTitle("Filter Flights")
            .navigationBarItems(leading: cancel, trailing: done)
        }
    }
    
    var cancel: some View {
        Button("Cancel") {
            self.isPresented = false
        }
    }
    var done: some View {
        Button("Done") {
            print("dest: \(self.draft.destination.friendlyName)")
            if self.draft.destination != self.flightSearch.destination {
                draft.destination.fetchIncomingFlights()
            }
            self.flightSearch = self.draft
            self.isPresented = false
        }
    }
}

//struct FilterFlights_Previews: PreviewProvider {
//    static var previews: some View {
//        FilterFlights()
//    }
//}
