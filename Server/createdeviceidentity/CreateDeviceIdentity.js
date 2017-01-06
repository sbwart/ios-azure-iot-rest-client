 'use strict';

 var iothub = require('azure-iothub');

 var connectionString = 'HostName=IoTPOCGateway.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=dEwJc/FoqoNKWyziMuRwM9jpBR29ZTZg1Klxzec58mA=';

 var registry = iothub.Registry.fromConnectionString(connectionString);

 var device = new iothub.Device(null);
 device.deviceId = 'SW-LE6G8243N4C6Y1MN8D7J';
 registry.create(device, function(err, deviceInfo, res) {
   if (err) {
     registry.get(device.deviceId, printDeviceInfo);
   }
   if (deviceInfo) {
     printDeviceInfo(err, deviceInfo, res)
   }
 });

 function printDeviceInfo(err, deviceInfo, res) {
   if (deviceInfo) {
     console.log('Device ID: ' + deviceInfo.deviceId);
     console.log('Device key: ' + deviceInfo.authentication.symmetricKey.primaryKey);
   }
 }

