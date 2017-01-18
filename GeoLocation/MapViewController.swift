//
//  MapViewController.swift
//  GeoLocation
//
//  Created by Steve Wart on 12/18/16.
//  Copyright © 2016 Steve Wart. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxGeocoder
import CoreLocation

class MapViewController: UIViewController, MGLMapViewDelegate, PulleyPrimaryContentControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView : MGLMapView?
    @IBOutlet var controlsContainer: UIView!
    @IBOutlet var temperatureLabel: UILabel!

    @IBOutlet var temperatureLabelBottomConstraint: NSLayoutConstraint!
    
    private let temperatureLabelBottomDistance: CGFloat = 8.0
    
    // maintain a reference to the location manager for authorization requests
    let manager = CLLocationManager()
    let gateway = IotGateway()
    let directions = Directions.shared
    
    var annotation: MGLPointAnnotation?
    var lastLocation: CLLocation?
    var userId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView?.delegate = self
        mapView?.attributionButton.isHidden = true
        mapView?.logoView.isHidden = true
        
        controlsContainer.layer.cornerRadius = 10.0
        temperatureLabel.layer.cornerRadius = 7.0
        
        // Ensure user is logged in before collecting any data
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let client = delegate.client!
        
        if client.currentUser == nil {
            client.login(withProvider: "windowsazureactivedirectory", controller:self, animated:true) { user, error in
                print("User ID: \(user?.userId)")
                self.userId = user?.userId
                DispatchQueue.main.async {
                    self.startLocationServices()
                }
            }
        }
    }
    
    private func startLocationServices() {
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
            gateway.publishLocation(userId, location)
            lastUpdateTime = NSDate().timeIntervalSince1970
        }
        // zoom map view to user location (just once, at startup)
        // XXX there should be a compass icon to provide control
        if !didInitialZoom {
            mapView?.setCenter(coord, zoomLevel: 14.0, animated: true)
            didInitialZoom = true
        }
        lastLocation = location
    }
    
    func animateTo(placemark: Placemark) {
        if let point = annotation {
            mapView?.removeAnnotation(point)
        }
        annotation = MGLPointAnnotation()
        annotation?.coordinate = placemark.location!.coordinate
        annotation?.title = placemark.name
        annotation?.subtitle = placemark.qualifiedName
        mapView?.addAnnotation(annotation!)
        mapView?.setCenter(placemark.location!.coordinate, animated: true)
    }
    
    func distanceString(to: CLLocation) -> String {
        let distanceFormatter = LengthFormatter()
        let distance = lastLocation?.distance(from: to)
        return distanceFormatter.string(fromMeters: distance!)
    }
    
    func showDirectionsTo(placemark: Placemark) {
        if let from = lastLocation {
            let waypoints = [
                Waypoint(coordinate: from.coordinate),
                Waypoint(coordinate: placemark.location!.coordinate)
            ]
            let options = RouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifierAutomobile)
            options.includesSteps = true
            
            let _ = directions.calculate(options) { (waypoints, routes, error) in
                guard error == nil else {
                    print("Error calculating directions \(error)")
                    return
                }
                
                if let route = routes?.first, let leg = route.legs.first {
                    
                    // TODO populate the UI
                    print("Route via \(leg):")
                    
                    let distanceFormatter = LengthFormatter()
                    let formattedDistance = distanceFormatter.string(fromMeters:route.distance)
                    
                    let travelTimeFormatter = DateComponentsFormatter()
                    travelTimeFormatter.unitsStyle = .short
                    let formattedTravelTime = travelTimeFormatter.string(from: route.expectedTravelTime)
                    
                    print("Distance: \(formattedDistance); ETA: \(formattedTravelTime!)")
                    
                    for step in leg.steps {
                        print("\(step.instructions)")
                        let formattedDistance = distanceFormatter.string(fromMeters: step.distance)
                        print("- \(formattedDistance) - ")
                    }
                    
                    // Draw the route on the map
                    if route.coordinateCount > 0 {
                        // Convert the route's coordinates into a polyline
                        var coords = route.coordinates!
                        let line = MGLPolyline(coordinates: &coords, count: route.coordinateCount)
                        
                        self.mapView?.addAnnotation(line)
                        self.mapView?.setVisibleCoordinates(&coords, count: route.coordinateCount, edgePadding: UIEdgeInsets.zero, animated:true)
                    }
                }
            }
        }
    }
    
    func makeUIAdjustmentsForFullscreen(progress: CGFloat)
    {
        controlsContainer.alpha = 1.0 - progress
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat)
    {
        if distance <= 268.0
        {
            temperatureLabelBottomConstraint.constant = distance + temperatureLabelBottomDistance
        }
        else
        {
            temperatureLabelBottomConstraint.constant = 268.0 + temperatureLabelBottomDistance
        }
    }
    
    @IBAction func runPrimaryContentTransitionWithoutAnimation(sender: AnyObject) {
        
        if let drawer = self.parent as? PulleyViewController
        {
            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrimaryTransitionTargetViewController")
            
            drawer.setPrimaryContentViewController(controller: primaryContent, animated: false)
        }
    }
    
    @IBAction func runPrimaryContentTransition(sender: AnyObject) {
        
        if let drawer = self.parent as? PulleyViewController
        {
            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrimaryTransitionTargetViewController")
            
            drawer.setPrimaryContentViewController(controller: primaryContent, animated: true)
        }
    }
}

