//
//  SavedTableViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 6/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit

import GooglePlaces

class SavedTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {

    let CELL_PLACE = "savedPlaceCell"
    
    var allSavedPlaces: [Place] = []
    var filteredSavedPlaces: [Place] = []
    
    var databaseController: DatabaseProtocol?
    var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        placesClient = appDelegate.placesClient
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Saved Place"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListner(listener: self)
    }
    
    @IBAction func addSavedPlace(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    var listenerType = ListenerType.places
    
    func onPlaceListChange(change: DatabaseChange, places: [Place]) {
        allSavedPlaces = places
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    func onTripChange(change: DatabaseChange, trips: [Trip]) {
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), searchText.count > 0 {
            filteredSavedPlaces = allSavedPlaces.filter({
                (place: Place) -> Bool in return place.name!.lowercased().contains(searchText)
            })
        } else {
            filteredSavedPlaces = allSavedPlaces
        }
        
        tableView.reloadData()
    }
    
    /**
     delete saved place
     */
    func deleteSavedPlace(indexPath: IndexPath) {
        let deletedPlace = filteredSavedPlaces[indexPath.row]
        let indexInAll = allSavedPlaces.firstIndex(of: deletedPlace)
        allSavedPlaces.remove(at: indexInAll!)
        
        filteredSavedPlaces.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        databaseController?.updateSavedPlace(place: deletedPlace, saved: false)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filteredSavedPlaces.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PLACE, for: indexPath) as! SavedPlaceTableViewCell
        let place = filteredSavedPlaces[indexPath.row]
        
        cell.placeIndexPath = indexPath
        cell.delegate = self
        cell.placeName.text = place.name
        cell.placeAddress.text = place.address
        
        // fetch place from the CoreData
        let placeId = filteredSavedPlaces[indexPath.row].id
        let fields: GMSPlaceField = GMSPlaceField(rawValue: GMSPlaceField.all.rawValue)!
        placesClient?.fetchPlace(fromPlaceID: placeId!, placeFields: fields, sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                print(place)
                // update photo for cell in saved place table
                if place.photos != nil {
                    let photoMetadata : GMSPlacePhotoMetadata = place.photos![0]
                    
                    self.placesClient?.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error loading photo metadata: \(error.localizedDescription)")
                            return
                        } else {
                            cell.placeImageView?.image = photo
                        }
                    })
                }
            }
        })
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destination = storyboard.instantiateViewController(withIdentifier: "PlaceDetailsViewController") as! PlaceDetailsViewController
//        let destination = PlaceDetailsViewController()
        let placeId = filteredSavedPlaces[indexPath.row].id
        
        let fields: GMSPlaceField = GMSPlaceField(rawValue: GMSPlaceField.all.rawValue)!
        placesClient?.fetchPlace(fromPlaceID: placeId!, placeFields: fields, sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                print(place)
                destination.place = place
                self.navigationController?.pushViewController(destination, animated: true)
            }
        })
    }


}

extension SavedTableViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Get the place name from 'GMSAutocompleteViewController'
        let fetchedPlace = databaseController?.getPlace(id: place.placeID!)
        if (fetchedPlace != nil) {
            if (fetchedPlace?.saved == false) {
                databaseController?.updateSavedPlace(place: fetchedPlace!, saved: true)
            } else {
                print("Place was already saved")
            }
            return
        }
        databaseController?.addPlace(id: place.placeID!, name: place.name!, address: place.formattedAddress!, latitude: Float(place.coordinate.latitude), longitude: Float(place.coordinate.longitude), saved: true)
        print("Place added")
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
