//
//  Place+CoreDataClass.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 19/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//
//

import Foundation
import CoreData
import GooglePlaces

@objc(Place)
public class Place: NSManagedObject {
    func fromGMSPlace(gmPlace: GMSPlace) {
        self.id = gmPlace.placeID
        self.address = gmPlace.formattedAddress
        self.latitude = Float(gmPlace.coordinate.latitude)
        self.longitude = Float(gmPlace.coordinate.longitude)
    }
}
