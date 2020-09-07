//
//  SavedPlaceTableViewCell.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 6/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit

class SavedPlaceTableViewCell: UITableViewCell {

    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var placeAddress: UILabel!
    
    var placeIndexPath: IndexPath!
    var delegate: SavedTableViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func deleteButtonOnClicked(_ sender: Any) {
        delegate.deleteSavedPlace(indexPath: placeIndexPath)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
