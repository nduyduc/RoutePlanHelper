//
//  Trip+CoreDataProperties.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 19/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//
//

import Foundation
import CoreData


extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var end_place: String?
    @NSManaged public var reminder: Bool
    @NSManaged public var start_place: String?
    @NSManaged public var start_date: String?
    @NSManaged public var transport_type: String?
    @NSManaged public var places: NSSet?

}

// MARK: Generated accessors for places
extension Trip {

    @objc(addPlacesObject:)
    @NSManaged public func addToPlaces(_ value: Place)

    @objc(removePlacesObject:)
    @NSManaged public func removeFromPlaces(_ value: Place)

    @objc(addPlaces:)
    @NSManaged public func addToPlaces(_ values: NSSet)

    @objc(removePlaces:)
    @NSManaged public func removeFromPlaces(_ values: NSSet)

}
