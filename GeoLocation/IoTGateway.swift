//
//  IoTGateway.swift
//  GeoLocation
//
//  Created by Steve Wart on 12/23/16.
//  Copyright © 2016 Steve Wart. All rights reserved.
//

import Foundation
import CoreLocation
import IDZSwiftCommonCrypto

class IotGateway {

    let hostname = "IoTPOCGateway"
    var policy : String?
    var sharedkey : String?
    
    // create key of 20 random 32-bit values
    func generate() -> String {
        var key = "TM-"
        let alphabet = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
                        "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "X", "Y", "Z"]
        for _ in 0 ..< 20 {
            let index = Int(arc4random_uniform(32))
            key.append(alphabet[index])
        }
        return key
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
                let encoded = NSData(bytes: digest, length: digest.count)
                    .base64EncodedString()
                    .addingPercentEncoding(withAllowedCharacters:.alphanumerics)!
                
                var token = "SharedAccessSignature sr=\(uri)&sig=\(encoded)&se=\(expires)"
                if let policy = policyName {
                    token = token + "&skn=" + policy
                }
                return token
            }
        }
        return nil
    }
    
    func publishLocation(_ location: CLLocation) {
        let profile = DeviceProfile.defaultProfile()

        // updates will not be able to start until device is registered
        if !profile.isRegistered() {
            print("Device is not yet registered, no updates will be posted")
            return
        }

        let deviceid = profile.getDeviceId()
        let devicekey = profile.getDeviceKey()
        
        // endpoint for Azure device to cloud messaging
        let endpoint = "\(hostname).azure-devices.net/devices/\(deviceid)"

        if let token = generateSASToken(resourceUri: endpoint, signingKey: devicekey, policyName: nil, expiresInMinutes: 60.0) {
            
            let coord = location.coordinate
            let timestamp = location.timestamp.timeIntervalSince1970
            let item = "{\"timestamp\":\(timestamp), \"device\":\"\(deviceid)\", \"latitude\":\(coord.latitude), \"longitude\":\(coord.longitude)}"
            
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
    
    func registerDevice(_ then: @escaping (_: Data?) -> Void) {
        // generate a unique device key
        let deviceid = generate()
        
        let path = Bundle.main.path(forResource: "registration", ofType: "plist")!
        if let lookup = NSDictionary(contentsOfFile: path) {
            print("Successfully read registration profile from \(path)")
            policy = lookup.object(forKey: "name") as? String
            sharedkey = lookup.object(forKey: "primary") as? String
        }
        else {
            // XXX nothing really to be done here - app is not installed correctly?
            print("Registration profile not found at \(path)")
            return
        }
        
        // endpoint for Azure device to cloud messaging
        let endpoint = "\(hostname).azure-devices.net/devices/\(deviceid)"
        
        if let token = generateSASToken(resourceUri: endpoint, signingKey: sharedkey!, policyName: policy!, expiresInMinutes: 60.0) {
            
            let item = "{\"deviceId\":\"\(deviceid)\"}"
            
            if let body = item.data(using: .utf8) {
                // HTTP PUT request
                var request = URLRequest(url: URL(string: "https://\(hostname).azure-devices.net/devices/\(deviceid)?api-version=2016-02-03")!)
                request.httpMethod = "PUT"
                request.httpBody = body
                request.setValue(token, forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("*", forHTTPHeaderField: "If-None-Match")   // will fail with 412 if resource already exists
                
                print("sending JSON data to server: \(String(data:body, encoding:.utf8)!)")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard error == nil else {                                                 // check for fundamental networking error
                        print("error=\(error)")
                        // unable to register device. notify caller to retry later
                        then(nil)
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode / 100 != 2  {           // check for http errors
                        print("statusCode should be 2xx, but is \(httpStatus.statusCode)")
                        print("response = \(httpStatus)")
                        // unable to register device. notify caller to retry later
                        then(nil)
                        return
                    }
                    // successfully registered device
                    then(data)
                }
                task.resume()
            }
        }
    }
}


