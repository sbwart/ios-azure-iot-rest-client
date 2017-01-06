//
//  DeviceProfile.swift
//  GeoLocation
//
//  Created by Steve Wart on 12/24/16.
//  Copyright © 2016 Steve Wart. All rights reserved.
//

import Foundation

enum DeviceProfileError : Error {
    case deviceAlreadyRegistered
}

class DeviceProfile {
    
    private static let defaultInstance = DeviceProfile()

    private let gateway = IotGateway()
    
    private var deviceId : String?
    private var primaryKey : String?
    private var secondaryKey : String?
    
    private init() {

        let path = profilePath()

        if let lookup = NSDictionary(contentsOfFile: path) {
            print("Reading device profile from \(path)")
            readDeviceKeys(lookup)
        }
        else {
            print("Device profile not found at \(path)")
        }
    }
    
    private func profilePath() -> String {
        let docpaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let directory = docpaths[0] as String
        return directory.appending("/deviceProfile.plist")
    }
    
    static func defaultProfile() -> DeviceProfile {
        return defaultInstance
    }
    
    // return the device ID
    func getDeviceId() -> String {
        return deviceId!
    }
    
    // Return the base64-encoded representation of the device symmetric key
    func getDeviceKey() -> String {
        return primaryKey!
    }
    
    func isRegistered() -> Bool {
        return deviceId != nil
    }
    
    // retry registration some time in the future : return immediately so we don't leave a bunch
    // of incomplete requests lying around
    func resecheduleRegistration() {
        DispatchQueue.global(qos: .userInitiated).async {
            Thread.sleep(forTimeInterval: 10.0)
            try! self.register()
        }
    }
    
    func readDeviceKeys(_ from: NSDictionary) {
        self.deviceId = from.object(forKey: "deviceId") as? String
        let auth = from.object(forKey: "authentication") as! NSDictionary
        let keys = auth.object(forKey:"symmetricKey") as! NSDictionary
        self.primaryKey = keys.object(forKey: "primaryKey") as? String
        self.secondaryKey = keys.object(forKey: "secondaryKey") as? String
    }
    
    func register() throws {
        // don't proceed if this device is already registered
        if deviceId != nil {
            throw DeviceProfileError.deviceAlreadyRegistered
        }

        // dispatch background process to call registration API
        DispatchQueue.global(qos: .userInitiated).async {
            self.gateway.registerDevice({ result in
                
                if let dict = result {
                    
                    self.readDeviceKeys(dict)
                    
                    DispatchQueue.main.async {
                        print("Device ID: \(self.deviceId)")
                        print("Device Primary Key: \(self.primaryKey)")
                        print("Device Secondary Key: \(self.secondaryKey)")
                        
                        let path = self.profilePath()
                        dict.write(toFile: path, atomically: true)
                    }
                }
                else {
                    self.resecheduleRegistration()
                    return
                }
            })
        }
    }
}

