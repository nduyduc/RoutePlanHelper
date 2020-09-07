//
//  AboutViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 14/6/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var fscalendar: UITextView!
    
    @IBOutlet weak var swiftyjson: UITextView!
    
    @IBOutlet weak var alamofire: UITextView!
    
    @IBOutlet weak var tutorial1: UITextView!
    
    @IBOutlet weak var tutorial2: UITextView!
    
    @IBOutlet weak var tutorial3: UITextView!
    
    @IBOutlet weak var tutorial4: UITextView!
    
    @IBOutlet weak var tutorial5: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fscalendar.attributedText = getAttributedString(url: "cocoapods.org/pods/FSCalendar", name: nil)
        fscalendar.isUserInteractionEnabled = true
        fscalendar.isEditable = false
        
        swiftyjson.attributedText = getAttributedString(url: "cocoapods.org/pods/SwiftyJSON", name: nil)
        swiftyjson.isUserInteractionEnabled = true
        swiftyjson.isEditable = false
        
        alamofire.attributedText = getAttributedString(url: "cocoapods.org/pods/Alamofire", name: nil)
        alamofire.isUserInteractionEnabled = true
        alamofire.isEditable = false
        
        tutorial1.attributedText = getAttributedString(url: "youtu.be/qsCkt4q6oyE", name: "Link")
        tutorial1.isUserInteractionEnabled = true
        tutorial1.isEditable = false
        
        tutorial2.attributedText = getAttributedString(url: "youtu.be/S5i8n_bqblE", name: "Link")
        tutorial2.isUserInteractionEnabled = true
        tutorial2.isEditable = false
        
        tutorial3.attributedText = getAttributedString(url: "youtu.be/n9NhtI2XlGM", name: "Link")
        tutorial3.isUserInteractionEnabled = true
        tutorial3.isEditable = false
        
        tutorial4.attributedText = getAttributedString(url: "medium.com/@brianclouser/swift-3-creating-a-custom-view-from-a-xib-ecdfe5b3a960", name: "Link")
        tutorial4.isUserInteractionEnabled = true
        tutorial4.isEditable = false
        
        tutorial5.attributedText = getAttributedString(url: "youtu.be/rVmxXpI28zU", name: "Link")
        tutorial5.isUserInteractionEnabled = true
        tutorial5.isEditable = false
    }
    
    func getAttributedString(url: String, name: String?) -> NSAttributedString {
        var nameStr: String
        if name == nil {
            nameStr = url
        } else {
            nameStr = name!
        }
        let attributedString = NSMutableAttributedString(string: nameStr)
        attributedString.setAttributes([.link: "https://\(url)"], range: NSMakeRange(0, nameStr.count))
        return attributedString
    }
}
