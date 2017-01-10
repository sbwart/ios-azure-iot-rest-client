//
//  StreetAddressFormatter.swift
//  GeoLocation
//
//  Created by Steve Wart on 1/10/17.
//  Copyright © 2017 Steve Wart. All rights reserved.
//

import Foundation
import Contacts

class StreetAddressFormatter {
 
    func string(from: CNPostalAddress) -> String {
        return "\(from.city), \(from.state), \(from.country)"
    }
}
