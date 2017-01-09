//
//  ViewController.swift
//  GeoLocation
//
//  Created by Steve Wart on 12/18/16.
//  Copyright © 2016 Steve Wart. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation

class ViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView : MGLMapView?
    // need to maintain a reference to the location manager for authorization requests
    let manager = CLLocationManager()
    let gateway = IotGateway()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView?.delegate = self
        mapView?.attributionButton.isHidden = true
        mapView?.logoView.isHidden = true
        
        // Location Services
        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 500
            manager.pausesLocationUpdatesAutomatically = true
            // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
            manager.requestAlwaysAuthorization()
            // we only want significant updates - app will be started in background
            manager.startMonitoringSignificantLocationChanges()
            mapView!.showsUserLocation = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // send updates every 15 minutes
    // TODO this should be adapted to every 5 minutes when close to destination
    var desiredInterval = 15.0 * 60
    var lastUpdateTime = 0.0
    
    var didInitialZoom = false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        let speed = location.speed
        let coord = location.coordinate
        let dt = NSDate().timeIntervalSince1970 - lastUpdateTime
        if dt >= desiredInterval {
            print("Send to server lat: \(coord.latitude), lon: \(coord.longitude), speed: \(speed)", terminator:"\n")
            gateway.publishLocation(location)
            lastUpdateTime = NSDate().timeIntervalSince1970
        }
        // zoom map view to user location (just once, at startup)
        // XXX there should be a compass icon to provide control
        if !didInitialZoom {
            mapView?.setCenter(coord, zoomLevel: 14.0, animated: true)
            didInitialZoom = true
        }
    }
}

