//
//  LocationDetailViewController.swift
//  GeoLocation
//
//  Created by Steve Wart on 1/10/17.
//  Copyright © 2017 Steve Wart. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxGeocoder

class LocationDetailViewController : UITableViewController {
    
    var placemark : Placemark?
    var mapViewController : MapViewController?
    let formatter = CNPostalAddressFormatter()
    let directions = Directions.shared
    
    @IBOutlet var nameLabel : UILabel?
    @IBOutlet var distanceLabel : UILabel?
    @IBOutlet var addressLabel : UILabel?
    @IBOutlet var phoneLabel : UILabel?
    @IBOutlet var directionsButton : UIButton?
    
    @IBAction func navigateToLocation() {
        mapViewController?.showDirectionsTo(placemark:self.placemark!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        directionsButton?.backgroundColor = self.view.tintColor
        directionsButton?.layer.cornerRadius = 10
        directionsButton?.clipsToBounds = true
    }
    
    func set(mapViewController: MapViewController) {
        self.mapViewController = mapViewController
    }

    func set(placemark: Placemark) {
        // force the controller to load the view hierarchy so outlets are populated
        let _ = self.view
        self.placemark = placemark
        self.nameLabel?.text = placemark.name
        self.addressLabel?.text = formatter.string(from: placemark.postalAddress!)
        self.phoneLabel?.text = placemark.phoneNumber
        self.distanceLabel?.text = mapViewController?.distanceString(to:placemark.location!)
    }
}
