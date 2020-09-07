//
//  DatabaseProtocol.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 6/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import Foundation

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case trips
    case places
    case all
}

protocol  DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onTripChange(change: DatabaseChange, trips: [Trip])
    func onPlaceListChange(change: DatabaseChange, places: [Place])
}

protocol DatabaseProtocol: AnyObject {
    
    func addPlace(id: String, name: String, address: String, latitude: Float, longitude: Float, saved: Bool) -> Place
    func addTrip(startId: String, startDate: String) -> Trip
    func addPlaceToTrip(place: Place, trip: Trip, asStartPlace: Bool?) -> Bool
    func deletePlace(place: Place)
    func deleteTrip(trip: Trip)
    func removePlaceFromTrip(place: Place, trip: Trip)
    func updateSavedPlace(place: Place, saved: Bool)
    func updateTrip(trip: Trip, startId: String, endId: String?, transport: String?, reminder: Bool?)
    func getPlace(id: String) -> Place?
    func getTrip(date: String) -> Trip?
    func duplicateTrip(trip: Trip, startDate: String) -> Trip
    
    func addListener(listener: DatabaseListener)
    func removeListner(listener: DatabaseListener)
}
