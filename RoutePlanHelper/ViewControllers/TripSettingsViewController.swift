//
//  TripSettingsViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 4/6/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import GooglePlaces

class TripSettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var databaseController: DatabaseProtocol?
    
    var trip: Trip!
    
    var startPlace: Place!
    
    var endPlace: Place!

    var delegate: TripViewController!
    
    @IBOutlet weak var travelModeTF: UITextField!
    
    @IBOutlet weak var startPlaceTF: UITextField!
    
    var travelModePicker: UIPickerView!
    var startPlacePicker: UIPickerView!
    
    var travelMode = ["Driving", "Walking", "Public transport"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        travelModeTF.text = getTravelModeText(travelMode: trip.transport_type!)
        
        startPlace = databaseController?.getPlace(id: trip.start_place!)
        
        if (trip.end_place != nil) {
            endPlace = databaseController?.getPlace(id: trip.end_place!)
        }
        
        startPlaceTF.text = startPlace.name
        
        travelModePicker = UIPickerView()
        travelModePicker.delegate = self
        
        travelModeTF.inputView = travelModePicker
        
        startPlacePicker = UIPickerView()
        startPlacePicker.delegate = self
        
        startPlaceTF.inputView = startPlacePicker
        
        self.navigationItem.title = "Trip Settings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonClicked(_:)))
    }
    
    func getTravelModeText(travelMode: String) -> String {
        switch travelMode {
        case "driving":
            return self.travelMode[0]
        case "walking":
            return self.travelMode[1]
        case "transit":
            return self.travelMode[2]
        default:
            return "Driving"
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == travelModePicker {
            return 3
        } else {
            return delegate.currentTripPlaces.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == travelModePicker {
            return travelMode[row]
        } else {
            return delegate.currentTripPlaces[row].name
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case travelModePicker:
            travelModeTF.text = travelMode[row]
            break
        case startPlacePicker:
            startPlaceTF.text = delegate.currentTripPlaces[row].name
            break
        default:
            break
        }
    }

    @objc func doneButtonClicked(_ sender: AnyObject?) {
        var transport_type: String?
        switch travelMode.firstIndex(of: travelModeTF.text!) {
        case 0:
            transport_type = "driving"
        case 1:
            transport_type = "walking"
        case 2:
            transport_type = "transit"
        default:
            break
        }
        let startPlaceId = delegate.currentTripPlaces[startPlacePicker.selectedRow(inComponent: 0)].id
//        print(transport_type)
//        print(startPlaceId)
        databaseController?.updateTrip(trip: self.trip, startId: startPlaceId!, endId: nil, transport: transport_type, reminder: false)
        print(self.trip)
        self.delegate.displayMessage(title: "Trip Settings Saved", message: "Trip Settings has been updated", popViewController: true)
    }

}
