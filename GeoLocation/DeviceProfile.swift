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

        if let lookup = try? Data (contentsOf: path) {
            print("Reading device profile from \(path)")
            readDeviceKeys(lookup)
        }
        else {
            print("Device profile not found at \(path)")
        }
    }
    
    private func profilePath() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        
        for file in try! FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            print(file)
        }
        
        return directory.appendingPathComponent("deviceProfile.plist")
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
    
    // assume device data is serialized application/json
    func readDeviceKeys(_ from: Data) {
        if let json = try? JSONSerialization.jsonObject(with: from, options: .mutableContainers) {
            let dict = json as! NSDictionary
            self.deviceId = dict.object(forKey: "deviceId") as? String
            let auth = dict.object(forKey: "authentication") as! NSDictionary
            let keys = auth.object(forKey:"symmetricKey") as! NSDictionary
            self.primaryKey = keys.object(forKey: "primaryKey") as? String
            self.secondaryKey = keys.object(forKey: "secondaryKey") as? String
        }
    }
    
    func register() throws {
        // don't proceed if this device is already registered
        if deviceId != nil {
            throw DeviceProfileError.deviceAlreadyRegistered
        }

        // dispatch background process to call registration API
        DispatchQueue.global(qos: .userInitiated).async {
            self.gateway.registerDevice({ result in
                
                if let data = result {
                    
                    self.readDeviceKeys(data)
                    
                    DispatchQueue.main.async {
                        print("Device ID: \(self.deviceId)")
                        print("Device Primary Key: \(self.primaryKey)")
                        print("Device Secondary Key: \(self.secondaryKey)")
                        
                        let path = self.profilePath()
                        if let _ = try? data.write(to: path) {
                            print("Successfully wrote device registration info")
                        }
                        else {
                            print("Failed to write device registration info")
                            self.resecheduleRegistration()
                        }
                    }
                }
                else {
                    self.resecheduleRegistration()
                }
            })
        }
    }
}

