//
//  AddPlaceToTripViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 18/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import GooglePlaces

class AddPlaceToTripViewController: UIViewController, UITextFieldDelegate {
    
    var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var placeName: UITextField!
    
    @IBOutlet weak var date: UITextField!
    
    @IBOutlet weak var asStartPlaceSwitch: UISwitch!
    
    private var datePicker: UIDatePicker?
    
    var place: GMSPlace!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        // set title, done button on navigation bar
        self.navigationItem.title = "Add Place To Trip"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonClicked(_:)))
        
        placeName.text = place.name
        placeName.delegate = self
        
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self, action: #selector(self.dateChanged(datePicker:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
        
        date.placeholder = "Select Date"
        date.inputView = datePicker
    }
    
    @objc func viewTapped(gestureRecognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    /**
     Once Date in datePicker changed, change the date in TextField
     - parameters:
        - datePicker: the datePicker in TextField
     */
    @objc func dateChanged(datePicker: UIDatePicker) {
        date.text = formatDate(date: datePicker.date)
    }
    
    /**
     Take input a Date and transform to a String
     - parameters:
        - date: the input Date
     - returns:
        a String formatted of a Date
     */
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: date)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
    
    /**
     Handle Done Button Clicked. Add a Place to a Trip
     */
    @objc func doneButtonClicked(_ sender: AnyObject?) {
        // error prevention: check the TextField whether it's empty
        let today = Date()
        if datePicker?.date == nil || date.text == "" {
            displayMessage(title: "Add Place Unsuccessfully", message: "You need to enter the Date", popViewController: false)
            return
        }
        // error prevention: past date is not allowed
        if today > datePicker!.date {
            displayMessage(title: "Add Place Unsuccessfully", message: "You cannot enter the past Date ", popViewController: false)
            return
        }
        
        var fetchedPlace = databaseController?.getPlace(id: place.placeID!)
        // if the place was not saved in CoreData, add it to CoreData

        if (fetchedPlace == nil) {
            fetchedPlace = databaseController?.addPlace(id: place.placeID!, name: place.name!, address: place.formattedAddress!, latitude: Float(place.coordinate.latitude), longitude: Float(place.coordinate.longitude), saved: false)
            print("Place added")
        }
        let startDate = self.date.text
        var fetchedTrip = databaseController?.getTrip(date: startDate!)
        if (fetchedTrip != nil) {
            let _ = databaseController?.addPlaceToTrip(place: fetchedPlace!, trip: fetchedTrip!, asStartPlace: asStartPlaceSwitch.isOn)
            print("Add place to existing trip")
        } else {
            fetchedTrip = databaseController?.addTrip(startId: place.placeID!, startDate: startDate!)
//            print(fetchedTrip)
            let _ = databaseController?.addPlaceToTrip(place: fetchedPlace!, trip: fetchedTrip!, asStartPlace: true)
        }
        
        displayMessage(title: "Add Place Successfully", message: "The Place has been added to Trip on \(date.text ?? "")", popViewController: true)
    }
    
    /**
     Display message to the Screen
     - parameters:
        - title: Title string
        - message: Message string
        - popViewController: if flag = true, pop view controller from navigationController
     */
    func displayMessage(title: String, message: String, popViewController: Bool) {
        // Setup an alert to show user details about the Person
        // UIAlertController manages an alert instance
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        if !popViewController {
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        } else {
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action in
                self.navigationController?.popViewController(animated: true)
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }
}
