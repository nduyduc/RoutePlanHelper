//
//  Place+CoreDataProperties.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 19/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//
//

import Foundation
import CoreData


extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var address: String?
    @NSManaged public var id: String?
    @NSManaged public var latitude: Float
    @NSManaged public var longitude: Float
    @NSManaged public var name: String?
    @NSManaged public var saved: Bool
    @NSManaged public var trips: NSSet?

}

// MARK: Generated accessors for trips
extension Place {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: Trip)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: Trip)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)

}
