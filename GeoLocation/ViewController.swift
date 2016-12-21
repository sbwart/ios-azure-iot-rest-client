//
//  ViewController.swift
//  GeoLocation
//
//  Created by Steve Wart on 12/18/16.
//  Copyright © 2016 Steve Wart. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import IDZSwiftCommonCrypto

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView : MKMapView?
    // need to maintain a reference to the location manager for authorization requests
    var manager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView?.delegate = self
        
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        let speed = location.speed
        let coord = location.coordinate
        let dt = NSDate().timeIntervalSince1970 - lastUpdateTime
        if dt >= desiredInterval {
            print("Send to server lat: \(coord.latitude), lon: \(coord.longitude), speed: \(speed)", terminator:"\n")
            publishLocation(location)
            lastUpdateTime = NSDate().timeIntervalSince1970
        }
//        print("Received lat: \(coord.latitude), lon: \(coord.longitude), speed: \(speed), time: \(dt)", terminator:"\n")
    }

    func generateSASToken(resourceUri: String, signingKey: String, policyName: String?, expiresInMinutes: Double) -> String? {
        if let uri = resourceUri.lowercased().addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.lowercased() {

            // set expiration in seconds
            let expires = Int(ceil(NSDate().timeIntervalSince1970 + expiresInMinutes * 60.0))
            let toSign = uri + "\n" + String(expires)

            // use crypto
            let key = Data(base64Encoded: signingKey)
            let buffer = arrayFrom(string: toSign)
            
            if let digest = HMAC(algorithm:.sha256, key:key!).update(buffer:buffer, byteCount:buffer.count)?.final() {
                let encoded = NSData(bytes: digest, length: digest.count).base64EncodedString().addingPercentEncoding(withAllowedCharacters:.alphanumerics)!
                var token = "SharedAccessSignature sr=\(uri)&sig=\(encoded)&se=\(expires)"
                if let policy = policyName {
                    token = token + "&skn=" + policy
                }
                return token
            }
        }
        return nil
    }
    
//    func testHmac(signingKey: String, stringData: String) {
//        let key = Data(base64Encoded: signingKey)
//        let buffer = arrayFrom(string: stringData)
//        
//        if let digest = HMAC(algorithm:.sha256, key:key!).update(buffer:buffer, byteCount:buffer.count)?.final() {
//            let encoded = NSData(bytes: digest, length: digest.count).base64EncodedString().addingPercentEncoding(withAllowedCharacters:.alphanumerics)!
//            print("testHmac(\(stringData)) = \(encoded)")
//        }
//    }
    
    func publishLocation(_ location: CLLocation) {
        let hostname = "IoTPOCGateway"
        let deviceid = "ngscFirstNodeDevice"
        let endpoint = "\(hostname).azure-devices.net/devices/\(deviceid)"
        let devicekey = "wA18wu4ERemxetPFcavCZcG+Mb67t7zuUc6yl0yirCI="
        
//        testHmac(signingKey: devicekey, stringData: "abc")
        
        if let token = generateSASToken(resourceUri: endpoint, signingKey: devicekey, policyName: "device", expiresInMinutes: 60.0) {
            
            let coord = location.coordinate
            let now = NSDate().timeIntervalSince1970
            // TODO Use JSON Serialization
            let item = "{\"timestamp\":\(now), \"device\":\"\(deviceid)\", \"latitude\":\(coord.latitude), \"longitude\":\(coord.longitude)}"
            
            if let body = item.data(using: .utf8) {
                // HTTP POST request
                var request = URLRequest(url: URL(string: "https://\(hostname).azure-devices.net/devices/\(deviceid)/messages/events?api-version=2016-02-03")!)
                request.httpMethod = "POST"
                request.httpBody = body
                request.setValue(token, forHTTPHeaderField: "Authorization")
                
                print("sending JSON data to server: \(String(data:body, encoding:.utf8)!)")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard error == nil else {                                                 // check for fundamental networking error
                        print("error=\(error)")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode / 100 != 2 {           // check for http errors
                        print("statusCode should be 2xx, but is \(httpStatus.statusCode)")
                        print("response = \(response)")
                    }
                }
                task.resume()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let span = MKCoordinateSpanMake(0.02, 0.02)
        let region = MKCoordinateRegionMake(mapView.userLocation.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

