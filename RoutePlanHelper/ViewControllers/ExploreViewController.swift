//
//  FirstViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 5/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import Alamofire

class ExploreViewController: UIViewController {
    
    // default Location is Monash Clayton
    let defaultLocation = CLLocation(latitude: -37.907803, longitude: 145.133957)
    
    private let DIRECTION_API_KEY = "AIzaSyC0RE5kAF7azes_-hIdat3lVwXiUENHEQM"
    var locationManager = CLLocationManager()
    var mapView: GMSMapView!
    var zoomLevel: Float = 15.0
    var placesClient: GMSPlacesClient!
    
    var markersInTrip: [GMSMarker]!
    
    var placesInTrip: [Place]!
    
    var travelMode: String!
    
    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var placeDetailsView: PlaceDetailsView!
    
    @IBOutlet weak var heightPlaceDetails: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        placesClient = appDelegate.placesClient
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude, longitude: defaultLocation.coordinate.longitude, zoom: zoomLevel)
        
        let screenSize = UIScreen.main.bounds
        
        // Create GoogleMaps View
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), camera: camera)
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
     
        // Add mapView to View Controller
        view.addSubview(mapView)
        searchBar.placeholder = "Search"
        view.bringSubviewToFront(searchBar)
        view.bringSubviewToFront(placeDetailsView)
        
        // By default placeDetails tab is hidden
        placeDetailsView.isHidden = true
        placeDetailsView.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        navigationItem.title = "Explore"
    }
    
    /**
     Create Marker on the mapView
     - parameters:
        - titleMarker: title of the marker
        - redColor: true if the maker is red, otherwise maker is blue
        - latitude, longtitude: coordinate of the marker
     - returns:
        a GMSMarker represents the marker
     */
    func createMarker(titleMarker: String, redColor: Bool, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> GMSMarker {
        let maker = GMSMarker()
        maker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        maker.title = titleMarker
        if (!redColor) {
            maker.icon = GMSMarker.markerImage(with: .blue)
        }
        maker.map = self.mapView
        return maker
    }
    
    /**
     Re-focus a Map to show all the markers on the screen
     */
    func focusMapToShowAllMarkers() {
        let firstLocation = (markersInTrip.first)?.position
        var bounds = GMSCoordinateBounds(coordinate: firstLocation!, coordinate: firstLocation!)
        for marker in markersInTrip {
            bounds = bounds.includingCoordinate(marker.position)
            let update = GMSCameraUpdate.fit(bounds, withPadding: CGFloat(15))
            self.mapView.animate(with: update)
        }
    }
    
    /**
     Draw a path between 2 locations
     - parameters:
        - startLocation: starting place
        - endLocation: ending place
     */
    func drawPath(startLocation: Place, endLocation: Place) {
        let origin = startLocation.id
        let destination = endLocation.id
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=place_id:\(origin ?? "")&destination=place_id:\(destination ?? "")&mode=\(travelMode ?? "driving")&key=\(DIRECTION_API_KEY)"
        print(url)
        
        // use Alamofire to request from GoogleMaps Directions API
        Alamofire.request(url).responseJSON { response in
//            print(response.request as Any)
//            print(response.response as Any)
//            print(response.data as Any)
//            print(response.result as Any)
            do {
                let json = try JSON(data: response.data!)
                
                let routes = json["routes"].arrayValue
                
                // print route using Polyline
                for route in routes {
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 4
                    polyline.strokeColor = UIColor.red
                    polyline.map = self.mapView
                }
            } catch {
                print(error)
            }
        }
    }
    
    /**
     Draw route between multiple Places
     */
    func drawRoute() {
        self.mapView.clear()
        if (placesInTrip.count < 2) {
            return
        }
        // Create all the markers, startLocation is red marker
        markersInTrip = [GMSMarker]()
        for place in placesInTrip {
            var red = false
            if (placesInTrip.firstIndex(of: place) == 0) {
                red = true
            }
            markersInTrip.append(createMarker(titleMarker: place.name!, redColor: red, latitude: CLLocationDegrees(place.latitude), longitude: CLLocationDegrees(place.longitude)))
        }
        
        focusMapToShowAllMarkers()
        
        // Draw path in order of the placesInTrip array
        for i in 0...(placesInTrip.count-2) {
            drawPath(startLocation: placesInTrip[i], endLocation: placesInTrip[i+1])
        }
    }

    /**
     Handle when click search bar
     */
    @IBAction func searchBarTapped(_ sender: Any) {
        searchBar.resignFirstResponder()
        
        // present the Google Places Autocomplete View Controller
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    /**
     Handle when select a place from the Autocomplete Vuew Controller
     - parameters:
        - place: selected place
     */
    func selectPlace(place: GMSPlace) {
        mapView.clear()
        let selectedLocationCamera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: zoomLevel)
        mapView.camera = selectedLocationCamera
        createMarker(titleMarker: place.name!, redColor: true, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
    }
    
    func removeMarker() {
        mapView.selectedMarker = nil
    }
    
    /**
     handle add place to trip button in placeDetailsView
     - parameters:
        - place: selected place
     */
    func addPlaceToTrip(place: GMSPlace) {
        // go to AddPlaceToTripViewController
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destination = storyboard.instantiateViewController(withIdentifier: "AddPlaceToTripViewController") as! AddPlaceToTripViewController
        destination.place = place
        self.navigationController?.pushViewController(destination, animated: true)
        placeDetailsView.isHidden = true
    }
    
    //    func updateSearchResults(for searchController: UISearchController) {
//        let searchText = searchController.searchBar.text?.lowercased()
//
//        let token = GMSAutocompleteSessionToken.init()
//
//        // Create a type filter.
//        let filter = GMSAutocompleteFilter()
//        filter.type = .establishment
//
//        placesClient?.findAutocompletePredictions(fromQuery: searchText!, bounds: nil, boundsMode: GMSAutocompleteBoundsMode.bias, filter: filter, sessionToken: token, callback: { (results, error) in
//            if let error = error {
//                print("Autocomplete error: \(error)")
//                return
//            }
//            if let results = results {
//                for result in results {
//
//                }
//            }
//        })
//    }
}

extension ExploreViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        mapView.animate(to: camera)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

extension ExploreViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Get the place name from 'GMSAutocompleteViewController'
        selectPlace(place: place)
        // show the placeDetailsView, add Information to the view
        placeDetailsView.place = place
        placeDetailsView.firstLabel.text = place.name
        placeDetailsView.secondLabel.text = place.formattedAddress
        
        if place.phoneNumber != nil {
            placeDetailsView.phoneLabel.isHidden = false
            placeDetailsView.phoneIcon.isHidden = false
            placeDetailsView.phoneLabel.text = place.phoneNumber
            if place.rating != 0 {
                placeDetailsView.ratingLabel.isHidden = false
                placeDetailsView.starIcon.isHidden = false
                placeDetailsView.ratingLabel.text = NSString(format: "%.1f", place.rating) as String
                if place.website != nil {
                    placeDetailsView.websiteTV.isHidden = false
                    placeDetailsView.websiteIcon.isHidden = false
                    var urlString = place.website?.absoluteString
                    if (urlString?.hasPrefix("http://"))! {
                        urlString = String((urlString?.dropFirst(7))!)
                    }
                    
                    let attributedString = NSMutableAttributedString(string: urlString ?? "Website")
                    attributedString.setAttributes([.link: place.website], range: NSMakeRange(0, urlString!.count))
                    
                    placeDetailsView.websiteTV.attributedText = attributedString
                    placeDetailsView.websiteTV.isUserInteractionEnabled = true
                    placeDetailsView.websiteTV.isEditable = false
                    
                    placeDetailsView.websiteTV.linkTextAttributes = [
                        .foregroundColor: UIColor.blue
                    ]
                }
            }
        }
        
        placeDetailsView.isHidden = false
        // set current state is closed (minimized)
        placeDetailsView.currentState = .closed
        
        // add place photo to the placeDetailsView
        if place.photos != nil {
            let photoMetadata : GMSPlacePhotoMetadata = place.photos![0]
            
            self.placesClient?.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                if let error = error {
                    print("Error loading photo metadata: \(error.localizedDescription)")
                    return
                } else {
                    self.placeDetailsView.imageView.image = photo
                }
            })
        }
        
        heightPlaceDetails.constant = 120
        dismiss(animated: true, completion: nil)
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // Handle the error
        print("Error: ", error.localizedDescription)
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        // Dismiss when the user canceled the action
        dismiss(animated: true, completion: nil)
    }
}
