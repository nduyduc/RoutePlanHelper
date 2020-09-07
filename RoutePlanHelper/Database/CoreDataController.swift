//
//  CoreDataController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 6/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {    
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistantContainer: NSPersistentContainer
    
    var savedPlacesFetchedResultsController: NSFetchedResultsController<Place>?
    var tripFetchResultsController: NSFetchedResultsController<Trip>?
    
    override init() {
        persistantContainer = NSPersistentContainer(name: "RoutePlanHelper")
        persistantContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        super.init()
    }
    
    func saveContext() {
        if persistantContainer.viewContext.hasChanges {
            do {
                try persistantContainer.viewContext.save()
            } catch {
                fatalError("Failed to save data to Core Data: \(error)")
            }
        }
    }
    
    func addPlace(id: String, name: String, address: String, latitude: Float, longitude: Float, saved: Bool) -> Place {
        let place = NSEntityDescription.insertNewObject(forEntityName: "Place", into: persistantContainer.viewContext) as! Place
        place.id = id
        place.name = name
        place.address = address
        place.latitude = latitude
        place.longitude = longitude
        place.saved = saved
        saveContext()
        return place
    }
    
    func addTrip(startId: String, startDate: String) -> Trip {
        let trip = NSEntityDescription.insertNewObject(forEntityName: "Trip", into: persistantContainer.viewContext) as! Trip
        trip.start_place = startId
        trip.start_date = startDate
        trip.transport_type = "driving"
        saveContext()
        return trip
    }
    
    func addPlaceToTrip(place: Place, trip: Trip, asStartPlace: Bool?) -> Bool {
        guard let places = trip.places, places.contains(place) == false
            else {
                return false
            }
        trip.addToPlaces(place)
        if (asStartPlace == true) {
            trip.start_place = place.id
        }
        saveContext()
        return true
    }
    
    func deletePlace(place: Place) {
        persistantContainer.viewContext.delete(place)
        saveContext()
    }
    
    
    func deleteTrip(trip: Trip) {
        persistantContainer.viewContext.delete(trip)
        saveContext()
    }
    
    func removePlaceFromTrip(place: Place, trip: Trip) {
        trip.removeFromPlaces(place)
        saveContext()
    }
    
    func updateSavedPlace(place: Place, saved: Bool) {
        place.setValue(saved, forKey: "saved")
        saveContext()
    }
    
    func updateTrip(trip: Trip, startId: String, endId: String?, transport: String?, reminder: Bool?) {
        trip.setValue(startId, forKey: "start_place")
        if endId != nil {
            trip.setValue(endId, forKey: "end_place")
        }
        trip.setValue(transport, forKey: "transport_type")
        trip.setValue(reminder, forKey: "reminder")
    }
    
    func duplicateTrip(trip: Trip, startDate: String) -> Trip {
        let newTrip = NSEntityDescription.insertNewObject(forEntityName: "Trip", into: persistantContainer.viewContext) as! Trip
        newTrip.places = trip.places
        newTrip.start_place = trip.start_place
        newTrip.transport_type = trip.transport_type
        newTrip.start_date = startDate
        saveContext()
        return newTrip
    }
    
    func getPlace(id: String) -> Place? {
        let moc = persistantContainer.viewContext
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchResults: [Place]
        fetchRequest.predicate = predicate
        do {
            fetchResults = try moc.fetch(fetchRequest)
            print(fetchResults)
            if fetchResults.count > 0 {
                return fetchResults[0]
            }
        } catch let error {
            print("failed to fetch place object: \(error)")
        }
        return nil
    }
    
    func getTrip(date: String) -> Trip? {
        let moc = persistantContainer.viewContext
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let predicate = NSPredicate(format: "start_date == %@", date)
        let fetchResults: [Trip]
        fetchRequest.predicate = predicate
        do {
            fetchResults = try moc.fetch(fetchRequest)
            print(fetchResults)
            if fetchResults.count > 0 {
                return fetchResults[0]
            }
        } catch let error {
            print("failed to fetch place object: \(error)")
        }
        return nil
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == ListenerType.trips || listener.listenerType == ListenerType.all {
            listener.onTripChange(change: .update, trips: fetchAllTrips())
        }
        
        if listener.listenerType == ListenerType.places || listener.listenerType == ListenerType.all {
            listener.onPlaceListChange(change: .update, places: fetchSavedPlaces())
        }
    }
    
    func removeListner(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func fetchSavedPlaces() -> [Place] {
        if savedPlacesFetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "id", ascending: true)
            let savedPredicate = NSPredicate(format: "saved == YES")
            fetchRequest.sortDescriptors = [nameSortDescriptor]
            fetchRequest.predicate = savedPredicate
            savedPlacesFetchedResultsController = NSFetchedResultsController<Place>(
                fetchRequest: fetchRequest,
                managedObjectContext: persistantContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            savedPlacesFetchedResultsController?.delegate = self
            do {
                try savedPlacesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request failed: \(error)") }
        }
        var places = [Place]()
        if savedPlacesFetchedResultsController?.fetchedObjects != nil {
            places = (savedPlacesFetchedResultsController?.fetchedObjects)!
        }
        return places
    }
    
    func fetchAllTrips() -> [Trip] {
        if tripFetchResultsController == nil {
            let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "start_date", ascending: true)
            fetchRequest.sortDescriptors = [nameSortDescriptor]
            tripFetchResultsController = NSFetchedResultsController<Trip>(
                fetchRequest: fetchRequest,
                managedObjectContext: persistantContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            tripFetchResultsController?.delegate = self
            do {
                try tripFetchResultsController?.performFetch()
            } catch {
                print("Fetch Request failed: \(error)")
            }
        }
        var trips = [Trip]()
        if tripFetchResultsController?.fetchedObjects != nil {
            trips = (tripFetchResultsController?.fetchedObjects)!
        }
        return trips
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == savedPlacesFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.places || listener.listenerType == ListenerType.all {
                    listener.onPlaceListChange(change: .update, places: fetchSavedPlaces())
                }
            }
        }
        if controller == tripFetchResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.trips || listener.listenerType == ListenerType.all {
                    listener.onTripChange(change: .update, trips: fetchAllTrips())
                }
            }
        }
    }
}
