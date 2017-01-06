# ios-azure-iot-rest-client
Implementation of Azure registration &amp; device-to-cloud APIs in Swift for iOS 10.2

Not extensively tested. This is primarily a proof of concept to illustrate how to register a new device using the Azure IoT Hub.

You will need an Azure account. This repository is missing registration.plist which contains the profile name (default value is 'registryReadWrite'), and primary and secondary keys required to create a new device ID at the portal.

Documentation for the REST APIs can be found here:
https://docs.microsoft.com/en-us/rest/api/iothub/device-identities-rest

In order to construct the Authentication token, an SHA-256 HMAC must be used.

Apple does not currently provide a Swift-friendly way to access the Common Crypto APIs, so I used IDZSwiftCommonCrypto

https://github.com/iosdevzone/IDZSwiftCommonCrypto

Please refer to the above link for instructions on installing the dynamic framework
