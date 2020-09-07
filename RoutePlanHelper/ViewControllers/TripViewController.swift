//
//  SecondViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 5/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import FSCalendar
import GooglePlaces
import UserNotifications

class TripViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UITableViewDelegate, UITableViewDataSource, DatabaseListener, UNUserNotificationCenterDelegate {
    
    let CELL_TRIP = "placeInTripCell"
    let CELL_BUTTON = "buttonCell"
    
    let SECTION_TRIP = 0
    let SECTION_BUTTON = 1
    
    var listenerType = ListenerType.trips
    
    @IBOutlet weak var calendar: FSCalendar!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var tripTableView: UITableView!
    
    var selectedDate: Date!
    
    var selectedTrip: Trip!
    
    var startPlace: Place!
    
    var currentTripPlaces: [Place] = []
    
    var databaseController: DatabaseProtocol?
    
    var placesClient: GMSPlacesClient!
    
    var center: UNUserNotificationCenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        placesClient = appDelegate.placesClient
        center = appDelegate.center
        
        center.delegate = self
        
        calendar.setScope(FSCalendarScope.week, animated: false)
        calendar.select(Date())
        dateLabel.text = formatDate(date: Date())
        selectedDate = calendar.selectedDate
        calendar.delegate = self
        
        tripTableView.delegate = self
        tripTableView.dataSource = self
        
        // get the trip in the selected date
        selectedTrip = databaseController?.getTrip(date: formatDate(date: Date()))
        updateView(trip: selectedTrip)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListner(listener: self)
    }
    
    func updateView(trip: Trip?) {
        if (trip != nil) {
            currentTripPlaces = selectedTrip.places?.allObjects as! [Place]
        } else {
            currentTripPlaces = []
        }
        if (currentTripPlaces.count > 0) {
            // move the start_place to first item of the array
            for i in 0...(currentTripPlaces.count - 1) {
                if currentTripPlaces[i].id == selectedTrip.start_place {
                    (currentTripPlaces[0], currentTripPlaces[i]) = (currentTripPlaces[i], currentTripPlaces[0])
                    break
                }
            }
            
            // run the algorithm to re-order the array
            let algorithm = RoutePlan()
            algorithm.delegate = self
            algorithm.travelMode = selectedTrip.transport_type
            algorithm.find_best_route(places: currentTripPlaces)
        
            startPlace = databaseController?.getPlace(id: selectedTrip.start_place!)
            nameLabel.text = "Trip From " + startPlace.name!
        } else {
            nameLabel.text = "You have not plan any trip"
        }
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // update the selectedDate and update the View
        selectedDate = calendar.selectedDate
        selectedTrip = databaseController?.getTrip(date: formatDate(date: selectedDate))
        updateView(trip: selectedTrip)
        tripTableView.reloadData()
        dateLabel.text = formatDate(date: selectedDate)
    }

    /**
     Format Date to type String
     - parameters:
        - date: given date
     - returns:
        a string represents a given date
     */
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: date)
    }
    
    /**
     Format Date And Time to type String
     - parameters:
        - date: given date and time
     - returns:
        a string represents a given date and time
     */
    func formatDateAndTime(dateAndTime: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm EEEE, d MMM yyyy"
        return formatter.string(from: dateAndTime)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SECTION_TRIP {
            return currentTripPlaces.count
        }
        // there are four button in the second section
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_TRIP {
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_TRIP, for: indexPath) as! TripTableViewCell
            cell.placeIndexPath = indexPath
            cell.delegate = self
            cell.placeNameLabel.text = currentTripPlaces[indexPath.row].name
            return cell
        }
        
        // assign label to four buttons in the second section
        let buttonCell = tableView.dequeueReusableCell(withIdentifier: CELL_BUTTON, for: indexPath)
        switch indexPath.row {
        case 0:
            buttonCell.textLabel?.text = "See On Map"
            break
        case 1:
            buttonCell.textLabel?.text = "Duplicate Trip"
            break
        case 2:
            buttonCell.textLabel?.text = "Trip Settings"
            break
        case 3:
            buttonCell.textLabel?.text = "Set Reminder"
            break
        default:
            break
        }
        buttonCell.textLabel?.textColor = UIColor(displayP3Red: 0.204, green: 0.472, blue: 0.965, alpha: 1)
        return buttonCell
    }
    
    var alert: UIAlertController!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_TRIP {
            // go to PLaceDetailsViewController
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let destination = storyboard.instantiateViewController(withIdentifier: "PlaceDetailsViewController") as! PlaceDetailsViewController
            //        let destination = PlaceDetailsViewController()
            let placeId = currentTripPlaces[indexPath.row].id
            
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
        } else {
            switch indexPath.row {
            case 0:
                if selectedTrip == nil {
                    tableView.deselectRow(at: indexPath, animated: true)
                    break
                }
                // switch to Explore tab, and show the route
                let navigationDestination = self.tabBarController?.viewControllers![0] as! UINavigationController
                let destination = navigationDestination.topViewController as! ExploreViewController
                destination.placesInTrip = currentTripPlaces
                destination.travelMode = selectedTrip.transport_type
                destination.drawRoute()
                self.tabBarController?.selectedIndex = 0
                break
            case 1:
                if selectedTrip == nil {
                    tableView.deselectRow(at: indexPath, animated: true)
                    break
                }
                
                // open the Alert, asking user to enter the date for Duplicate current trip
                alert = UIAlertController(title: "Duplicate Trip", message: "", preferredStyle: .alert )
                alert.addTextField { (textField: UITextField) -> Void in
                    let datePicker = UIDatePicker()
                    datePicker.datePickerMode = .date
                    datePicker.addTarget(self, action: #selector(self.dateChanged(datePicker:)), for: .valueChanged)
                    textField.placeholder = "Select Date"
                    textField.inputView = datePicker
                }
    
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) -> Void in
                })
                
                let doneAciton = UIAlertAction(title: "Done", style: .default) { (action: UIAlertAction) in
                    let today = Date()
                    if self.alert.textFields![0].text == "" {
                        self.displayMessage(title: "Duplicate Trip Unsuccessfully", message: "You need to enter the Date", popViewController: false)
                        return
                    }
                    if today > self.getDateFromText(dateText: self.alert.textFields![0].text!) {
                        self.displayMessage(title: "Duplicate Trip Unsuccessfully", message: "You cannot enter the past Date ", popViewController: false)
                        return
                    }
                    let _ = self.databaseController?.duplicateTrip(trip: self.selectedTrip, startDate: self.alert.textFields![0].text!)
                    self.displayMessage(title: "Duplicate Trip Successfully", message: "New trip has been added on \(self.alert.textFields![0].text ?? "")", popViewController: false)
                }
                alert.addAction(cancelAction)
                alert.addAction(doneAciton)
                self.present(alert, animated: true, completion: nil)
                tableView.deselectRow(at: indexPath, animated: true)
                break
            case 2:
                // go top TripSettings ViewController
                if selectedTrip == nil {
                    tableView.deselectRow(at: indexPath, animated: true)
                    break
                }
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let destination = storyboard.instantiateViewController(withIdentifier: "TripSettingsViewController") as! TripSettingsViewController
                destination.trip = self.selectedTrip
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
                break
            case 3:
                if selectedTrip == nil {
                    tableView.deselectRow(at: indexPath, animated: true)
                    break
                }
                // open an Alert, ask user to enter the reminder time and date
                alert = UIAlertController(title: "Set Reminder", message: "", preferredStyle: .alert)
                alert.addTextField { (textField: UITextField) -> Void in
                    let datePicker = UIDatePicker()
                    datePicker.datePickerMode = .dateAndTime
                    datePicker.addTarget(self, action: #selector(self.dateAndTimeChanged(datePicker:)), for: .valueChanged)
                    textField.placeholder = "Select Reminder Time"
                    textField.inputView = datePicker
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) -> Void in })
                
                let doneAction = UIAlertAction(title: "Done", style: .default) { (action: UIAlertAction) in
                    let today = Date()
                    if self.alert.textFields![0].text == "" {
                        self.displayMessage(title: "Set Reminder Unsuccessfully", message: "You need to enter the Date and Time", popViewController: false)
                        return
                    }
                    if today > self.getDateAndTimeFromText(dateText: self.alert.textFields![0].text!) {
                        self.displayMessage(title: "Set Reminder Unsuccessfully", message: "You cannot enter the past Date and Time ", popViewController: false)
                        return
                    }
                    
                    // create local notification
                    let content = UNMutableNotificationContent()
                    content.title = "Trip Reminder"
                    content.body = "You planned a Trip on \(self.formatDate(date: self.selectedDate))"
                    content.sound = .default
                    
                    let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.getDateAndTimeFromText(dateText: self.alert.textFields![0].text!))
                    print(dateComponents)
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: "content", content: content, trigger: trigger)
                    self.center.add(request) { (error) in
                        if error != nil {
                            print(error)
                        }
                    }
                    self.displayMessage(title: "Set Reminder Successfully", message: "Reminder has been added at \(self.alert.textFields![0].text ?? "")", popViewController: false)
                }
                
                alert.addAction(cancelAction)
                alert.addAction(doneAction)
                self.present(alert, animated: true, completion: nil)
                tableView.deselectRow(at: indexPath, animated: true)
                break
            default:
                break
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    /**
     Format Date of type String to type Date
     - parameters:
        - dateText: given date of type String
     - returns:
        a date
     */
    func getDateAndTimeFromText(dateText: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm EEEE, d MMM yyyy"
        return formatter.date(from: dateText)!
    }
    
    /**
     Format Date of type String to type Date
     - parameters:
        - dateText: given date of type String
     - returns:
        a date and time
     */
    func getDateFromText(dateText: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.date(from: dateText)!
    }
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        let textField = alert.textFields![0] as UITextField
        textField.text = formatDate(date: datePicker.date)
    }
    
    @objc func dateAndTimeChanged(datePicker: UIDatePicker) {
        let textField = alert.textFields![0] as UITextField
        textField.text = formatDateAndTime(dateAndTime: datePicker.date)
    }
    
    /**
     delete a place from trip
     */
    func deletePlaceFromTrip(indexPath: IndexPath) {
        let deletedPlace = currentTripPlaces[indexPath.row]
        currentTripPlaces.remove(at: indexPath.row)
        tripTableView.deleteRows(at: [indexPath], with: .fade)
        databaseController?.removePlaceFromTrip(place: deletedPlace, trip: selectedTrip)
    }
    
    func onTripChange(change: DatabaseChange, trips: [Trip]) {
        for trip in trips {
            if (trip.start_date == formatDate(date: selectedDate)) {
                selectedTrip = trip
                updateView(trip: selectedTrip)
            }
        }
        tripTableView.reloadData()
    }
    
    func onPlaceListChange(change: DatabaseChange, places: [Place]) {
        
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

