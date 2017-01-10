//
//  LocationSearchViewController.swift
//  GeoLocation
//
//  Created by Steve Wart on 1/9/17.
//  Copyright © 2017 Steve Wart. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder

class LocationSearchViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, PulleyDrawerViewControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var gripperView: UIView!
    
    @IBOutlet var separatorHeightConstraint: NSLayoutConstraint!
    
    let geocoder = Geocoder.sharedGeocoder
    var places: [GeocodedPlacemark] = []
    let formatter = StreetAddressFormatter()
    var annotation : MGLPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        gripperView.layer.cornerRadius = 2.5
        separatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Tableview data source & delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath)
        let place = places[indexPath.row]
        cell.textLabel?.text = place.name
        cell.detailTextLabel?.text = formatter.string(from: place.postalAddress!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let drawer = self.parent as? PulleyViewController
        {
            let content = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationDetailViewController") as! LocationDetailViewController
            
            let placemark = places[indexPath.row]
            content.set(placemark: placemark)
            drawer.setDrawerPosition(position: .partiallyRevealed, animated: true)
            
            drawer.setDrawerContentViewController(controller: content, animated: false)
            
            // Add an annotation to the map & center at the selected location
            let primary = drawer.primaryContentViewController as? MapViewController
            let mapView = primary?.mapView

            if let point = annotation {
                mapView?.removeAnnotation(point)
            }
            annotation = MGLPointAnnotation()
            annotation?.coordinate = placemark.location.coordinate
            annotation?.title = placemark.name
            annotation?.subtitle = placemark.qualifiedName
            mapView?.addAnnotation(annotation!)
            mapView?.setCenter(placemark.location.coordinate, animated: true)
        }
    }
    
    // MARK: Drawer Content View Controller Delegate
    
    func collapsedDrawerHeight() -> CGFloat
    {
        return 68.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return 264.0
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed, .closed]
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController)
    {
        tableView.isScrollEnabled = drawer.drawerPosition == .open
        
        if drawer.drawerPosition != .open
        {
            searchBar.resignFirstResponder()
        }
    }
    
    // MARK: Search Bar delegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        if let drawerVC = self.parent as? PulleyViewController
        {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let options = ForwardGeocodeOptions(query: searchText)
        options.allowedISOCountryCodes = ["US", "CA"]
        options.focalLocation = CLLocation(latitude: 37.29, longitude: -121.96)
        options.allowedScopes = [.address, .pointOfInterest]
        options.maximumResultCount = 20
        
        let _ = geocoder.geocode(options) { (placemarks, attribution, error) in
            if let results = placemarks {
                self.places.removeAll()
                self.places.append(contentsOf: results)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
}
