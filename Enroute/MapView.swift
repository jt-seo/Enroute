//
//  MapView.swift
//  Enroute
//
//  Created by JT3 on 2020/10/13.
//  Copyright © 2020 JT. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

struct MapView: UIViewRepresentable {
    let annotations: [MKAnnotation]
    @Binding var selection: MKAnnotation?

    func makeUIView(context: Context) -> MKMapView {
        let mkMapView = MKMapView()
        mkMapView.delegate = context.coordinator
        mkMapView.addAnnotations(annotations)
        return mkMapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let annotation = selection {
            let pinDigree = 1.0
            let town = MKCoordinateSpan(latitudeDelta: pinDigree, longitudeDelta: pinDigree)
            uiView.setRegion(MKCoordinateRegion(center: annotation.coordinate, span: town), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selection: $selection)
    }
    
    static let MKAnnotationReuseIdentifier = "MapViewAnnotation"
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var selection: MKAnnotation?
        
        init(selection: Binding<MKAnnotation?>) {
            self._selection = selection
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKAnnotationReuseIdentifier) ??
                MKPinAnnotationView(annotation: annotation, reuseIdentifier: MKAnnotationReuseIdentifier)
            view.canShowCallout = true
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            self.selection = view.annotation
        }
    }
}
