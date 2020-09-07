//
//  RoutePlan.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 26/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class RoutePlan {
    
    private let DIRECTION_API_KEY = "AIzaSyCK1UtO6uNa3aZjO9FhI-RgiiR2pIwfkPs"

    let inf = 1000000000

    var best_places: [Place]!
    var adj = [[Int]]()
    
    var delegate: TripViewController!
    
    var travelMode: String!

    /**
     get data from Directions API
     - parameters:
        - places: list of all places:
        - i, j: index of the path between i-th place to j-th place to get data
        - n: the total number of place
     */
    func get_data(places: [Place], i: Int, j: Int, n: Int) {
        let origin = places[i].id
        let destination = places[j].id
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=place_id:\(origin ?? "")&destination=place_id:\(destination ?? "")&mode=\(travelMode ?? "driving")&key=\(DIRECTION_API_KEY)"
        print(url)
        Alamofire.request(url).responseJSON { response in
            print(response.request as Any)
            print(response.response as Any)
            print(response.data as Any)
            print(response.result as Any)
            do {
                let json = try JSON(data: response.data!)
                let routes = json["routes"].arrayValue
                if routes.count > 0 {
                    let route = routes[0]
                    let legs = route["legs"].arrayValue
                    if legs.count > 0 {
                        let leg = legs[0]
                        let distanceDict = leg["distance"].dictionary
                        let distance = distanceDict?["value"]?.stringValue
                        self.adj[i][j] = Int(distance!) ?? self.inf
                    }
                    if j == n-1 {
                        if i < n-2 {
                            self.get_data(places: places, i: i + 1, j: i + 2, n: n)
                        } else {
                            print(self.adj)
                            let result = self.dfs(placesId: [0], count: 1, n: n, distance: 0)
                            var placesResult = [Place]()
                            for i in 0...(n-1) {
                                placesResult.append(places[result.placesId[i]])
                            }
                            print(places)
                            print(result.placesId)
                            self.delegate.currentTripPlaces = placesResult
                            self.delegate.tripTableView.reloadData()
                        }
                    } else {
                        self.get_data(places: places, i: i, j: j + 1, n: n)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    /**
     Make adjancy array and DFS to find the most optimal route
     - parameters:
        - places: list of places in route
     */
    func make_adj_dfs(places: [Place]) {
        let n = places.count
        for i in 0...(n-1) {
            adj.append([])
            for j in 0...(n-1) {
                adj[i].append(inf)
            }
        }
        if n < 2 {
            return
        }
        get_data(places: places, i: 0, j: 1, n: n)
    }

    /**
     DFS to find the most optimal solution
     - parameters:
        - placesId: list of places id
        - count: the current number of places in current route
        - n: the total number of places
        - distance: the total distance of current route
     - returns:
        - placesId: list of places id represents the best solution
        - distance: the most optimal distance
     */
    func dfs(placesId: [Int], count: Int, n: Int, distance: Int) -> (placesId: [Int], distance: Int) {
        if count == n {
            return (placesId: placesId, distance: distance)
        }
        let u = placesId.last
        var best_result = (placesId: [Int](), distance: inf)
        for i in 0...(n-1) {
            if (i != u) {
                if adj[min(i, u!)][max(i, u!)] != inf && !placesId.contains(i) {
                    var newPlacesId = placesId
                    newPlacesId.append(i)
                    let result = dfs(placesId: newPlacesId, count: count + 1, n: n, distance: distance + adj[min(i, u!)][max(i, u!)])
                    if (result.distance < best_result.distance) {
                        best_result = result
                    }
                }
            }
        }
        return best_result
    }

    /**
     find the best route going through multiple places
     - parameters:
        - places: the list of places in route
     */
    func find_best_route(places: [Place]) {
        let n = places.count
        
        make_adj_dfs(places: places)

    }
}
