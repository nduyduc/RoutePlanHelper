//
//  PlaceDetailsView.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 10/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import GooglePlaces

enum State {
    case closed
    case open
}

extension State {
    var opposite: State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}

class PlaceDetailsView: UIView {
    
    @IBOutlet var view: UIView!
    
    var delegate: ExploreViewController!
    var databaseController: DatabaseProtocol?
    
    var place: GMSPlace!
    var currentState: State = .closed
    
    var imageView: UIImageView!
    var infoView: UIView!
    var detailsView: UIView!
    
    var firstLabel: UILabel!
    var secondLabel: UILabel!
    var closeButton: UIButton!
    var addToTripButton: UIButton!
    var saveButton: UIButton!
    
    var phoneLabel: UILabel!
    var ratingLabel: UILabel!
    var websiteTV: UITextView!
    
    var phoneIcon: UIImageView!
    var starIcon: UIImageView!
    var websiteIcon: UIImageView!
    
    @IBOutlet weak var secondSectionView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    /**
     setup the view when it's load
     */
    func setupView() {
        Bundle.main.loadNibNamed("PlaceDetailsView", owner: self, options: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        
        imageView = self.view.viewWithTag(1) as? UIImageView
        infoView = self.view.viewWithTag(2)
        detailsView = self.view.viewWithTag(3)
        
        firstLabel = view.viewWithTag(4) as? UILabel
        secondLabel = view.viewWithTag(5) as? UILabel
        
        closeButton = view.viewWithTag(6) as? UIButton
        closeButton.addTarget(self, action: #selector(self.closeButtonClicked(_:)), for: .touchUpInside)
        
        addToTripButton = view.viewWithTag(7) as? UIButton
        addToTripButton.layer.cornerRadius = 10
        addToTripButton.addTarget(self, action: #selector(self.addToTripButtonClicked(_:)), for: .touchUpInside)
        
        saveButton = view.viewWithTag(8) as? UIButton
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(self.saveButtonClicked(_:)), for: .touchUpInside)
        
        infoView.layer.cornerRadius = 5
        
        infoView.addGestureRecognizer(tapRecognizer)
        
        phoneLabel = view.viewWithTag(9) as? UILabel
        ratingLabel = view.viewWithTag(10) as? UILabel
        websiteTV = view.viewWithTag(11) as? UITextView
        
        phoneIcon = view.viewWithTag(12) as? UIImageView
        starIcon = view.viewWithTag(13) as? UIImageView
        websiteIcon = view.viewWithTag(14) as? UIImageView
        
        phoneLabel.isHidden = true
        ratingLabel.isHidden = true
        websiteTV.isHidden = true
        
        phoneIcon.isHidden = true
        starIcon.isHidden = true
        websiteIcon.isHidden = true
        
        self.addSubview(self.view)
    }
    
    // create tap gesture to minimize or maximize the view
    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(self.popupViewTapped(recognizer:)))
        return recognizer
    }()
    
    @objc func closeButtonClicked(_ sender: AnyObject?) {
        self.isHidden = true
//        delegate.removeMarker()
    }
    
    @objc func addToTripButtonClicked(_ sender: AnyObject?) {
        delegate.addPlaceToTrip(place: place)
    }
    
    /**
     Handle Save button, save the place to the CoreData
     */
    @objc func saveButtonClicked(_ sender: AnyObject?) {
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
        self.isHidden = true
//        delegate.removeMarker()
    }
    
    /**
     Handle the tap gesture, change the state of the view
     */
    @objc private func popupViewTapped(recognizer: UITapGestureRecognizer) {
        let state = currentState.opposite
        
        let transitionAnimator = UIViewPropertyAnimator(duration: 0, dampingRatio: 1, animations: {
            switch state {
            case .open:
                self.delegate.heightPlaceDetails.constant = self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.height
                self.view.frame = CGRect(x: 0, y: 0, width: self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.width, height: self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.height)
            case .closed:
                self.delegate.heightPlaceDetails.constant = 120
            }
        })
        
        transitionAnimator.addCompletion { position in
            switch position {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                ()
            }
            switch self.currentState {
            case .open:
                self.delegate.heightPlaceDetails.constant = self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.height
                self.view.frame = CGRect(x: 0, y: 0, width: self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.width, height: self.delegate.view.safeAreaLayoutGuide.layoutFrame.size.height)
                
            case .closed:
                self.delegate.heightPlaceDetails.constant = 120
            }
        }
        transitionAnimator.startAnimation()
    }
    
}
