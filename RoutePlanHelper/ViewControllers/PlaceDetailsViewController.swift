//
//  PlaceDetailsViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 11/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import GooglePlaces

class PlaceDetailsViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var placeNameLabel: UILabel!
    
    @IBOutlet weak var placeAddressLabel: UILabel!
    
    @IBOutlet weak var addToTripButton: UIButton!
    
    @IBOutlet weak var seeOnMapButton: UIButton!
    
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    
    @IBOutlet weak var placePhoneLabel: UILabel!
    
    @IBOutlet weak var placeRatingLabel: UILabel!
    
    @IBOutlet weak var websiteTextView: UITextView!
    
    @IBOutlet weak var phoneIcon: UIImageView!
    
    @IBOutlet weak var ratingIcon: UIImageView!
    
    @IBOutlet weak var websiteIcon: UIImageView!
    
    var place: GMSPlace!
    
    var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        placesClient = appDelegate.placesClient
        
        print(place)
        placeNameLabel.text = place.name
        placeAddressLabel.text = place.formattedAddress
    
        placePhoneLabel.isHidden = true
        phoneIcon.isHidden = true
        
        placeRatingLabel.isHidden = true
        ratingIcon.isHidden = true
        
        websiteTextView.isHidden = true
        websiteIcon.isHidden = true
        
        // get place data and display it on the view
        if place.phoneNumber != nil {
            placePhoneLabel.isHidden = false
            phoneIcon.isHidden = false
            placePhoneLabel.text = place.phoneNumber
            if place.rating != 0 {
                placeRatingLabel.isHidden = false
                ratingIcon.isHidden = false
                placeRatingLabel.text = NSString(format: "%.1f", place.rating) as String
                if place.website != nil {
                    websiteTextView.isHidden = false
                    websiteIcon.isHidden = false
                    var urlString = place.website?.absoluteString
                    if (urlString?.hasPrefix("http://"))! {
                        urlString = String((urlString?.dropFirst(7))!)
                    }
                    
                    let attributedString = NSMutableAttributedString(string: urlString ?? "Website")
                    attributedString.setAttributes([.link: place.website], range: NSMakeRange(0, urlString!.count))
                    
                    websiteTextView.attributedText = attributedString
                    websiteTextView.isUserInteractionEnabled = true
                    websiteTextView.isEditable = false
                    
                    websiteTextView.linkTextAttributes = [
                        .foregroundColor: UIColor.blue
                    ]
                }
            }
        }
        
        addToTripButton.layer.cornerRadius = 10
        seeOnMapButton.layer.cornerRadius = 10
        
        navigationItem.title = "Place Details"
        
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
    }
    
    /**
     handle addToTripButton
     */
    @IBAction func addToTripButtonClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let destination = storyboard.instantiateViewController(withIdentifier: "AddPlaceToTripViewController") as! AddPlaceToTripViewController
        destination.place = self.place
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    /**
     handle see on map button
     */
    @IBAction func seeOnMapButtonClicked(_ sender: Any) {
        let navigationDestination = self.tabBarController?.viewControllers![0] as! UINavigationController
        let destination = navigationDestination.topViewController as! ExploreViewController
        destination.selectPlace(place: place)
        self.tabBarController?.selectedIndex = 0
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pictureSegue" {
            let destination = segue.destination as! PictureViewController
            let cell = sender as! ImagesCollectionViewCell
            destination.image = cell.imageView.image
        }
    }

}

extension PlaceDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.place.photos == nil {
            return 0
        }
        return min(self.place.photos!.count, 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImagesCollectionViewCell
        
        if place.photos == nil {
            cell?.imageView.image = nil
            return cell!
        }
        // load photo on background thread and update the cell
        let photoMetadata : GMSPlacePhotoMetadata = place.photos![indexPath.row]
        DispatchQueue.global(qos: .userInitiated).async {
            self.placesClient?.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                if let error = error {
                    print("Error loading photo metadata: \(error.localizedDescription)")
                    return
                } else {
                    // update cell's photo
                    if let cellToUpdate = self.imagesCollectionView.cellForItem(at: indexPath) as? ImagesCollectionViewCell {
                        cellToUpdate.imageView.image = photo
                    }
                }
            })
        }

        return cell!
    }
}

extension PlaceDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = imagesCollectionView.frame.size
        return CGSize(width: size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
