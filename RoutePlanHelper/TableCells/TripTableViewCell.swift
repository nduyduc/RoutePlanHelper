//
//  TripTableViewCell.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 6/5/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit

class TripTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeNameLabel: UILabel!
    
    var delegate: TripViewController!
    var placeIndexPath: IndexPath!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        delegate.deletePlaceFromTrip(indexPath: placeIndexPath)
    }
    
}
