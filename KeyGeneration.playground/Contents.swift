//: Playground - noun: a place where people can play

import Foundation

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

let now = NSDate().timeIntervalSince1970
var keys = Set<String>()

for _ in 1 ... 100 {
    let key = generate()
    if keys.contains(key) {
        print("Duplicate key found: " + key)
    }
    keys.insert(key)
}

let duration = NSDate().timeIntervalSince1970 - now

print("generated \(keys.count) keys in \(duration) seconds")

print(generate())