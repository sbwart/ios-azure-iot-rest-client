'use strict';

var https = require('https');
var crypto = require('crypto');

// Use HTTP directly instead of Azure libraries
// var clientFromConnectionString = require('azure-iot-device-http').clientFromConnectionString;
// var Message = require('azure-iot-device').Message;
// var connectionString = 'HostName=IoTPOCGateway.azure-devices.net;DeviceId=ngscFirstNodeDevice;SharedAccessKey=PcMGegjfmDhD/YSD+NZmUXavNa4T5BnydISX8ci4rO0=';
// var client = clientFromConnectionString(connectionString);

function generateSasToken(resourceUri, signingKey, policyName, expiresInMins) {
  resourceUri = encodeURIComponent(resourceUri.toLowerCase()).toLowerCase();

  // Set expiration in seconds
  var expires = (Date.now() / 1000) + expiresInMins * 60;
  expires = Math.ceil(expires);
  var toSign = resourceUri + '\n' + expires;

  // Use crypto
  var hmac = crypto.createHmac('sha256', new Buffer(signingKey, 'base64'));
  hmac.update(toSign);
  var base64UriEncoded = encodeURIComponent(hmac.digest('base64'));

  // Construct autorization string
  var token = "SharedAccessSignature sr=" + resourceUri + "&sig=" + base64UriEncoded + "&se=" + expires;
  if (policyName) {
    token += "&skn=" + policyName;
  }
  return token;
}

// Device ID: SW-LE6G8243N4C6Y1MN8D7J
// Device key: ApaTnC95BYzZwUwYU56RaVdt9OnYUQj7NPZWwa/tPJo=

var hostname = 'IoTPOCGateway';
var deviceid = 'SW-ZY3D493E5E1Z101LXH5M';
var apiversion = '2016-02-03';
var endpoint = `${hostname}.azure-devices.net/devices/${deviceid}`;
var devicekey = 'lmxqfmfyNcvFMOb58F8aSjBDzrcIeTHXN3MNrCO6TOM=';  // symmetric key obtained when device is created
// var devicekey = 'wA18wu4ERemxetPFcavCZcG+Mb67t7zuUc6yl0yirCI=';   // device shared key

// policyName must not be specified when using a device symmetric key
var token = generateSasToken(endpoint, devicekey, null, 60);

// the skn field must be set to the name of the policy used when using a device shared key
// var token = generateSasToken(endpoint, devicekey, 'device', 60);

var options = {
  host: `${hostname}.azure-devices.net`,
  path: `/devices/${deviceid}/messages/events?api-version=${apiversion}`,
  method: 'POST',
  headers: {
    'Authorization': token
  }
};

function publish() {
  var windSpeed = 10 + (Math.random() * 4);
  var data = JSON.stringify({deviceId: deviceid, windSpeed: windSpeed});

  var request = https.request(options, function(res) {
    res.setEncoding('utf8');
    res.on('data', function(chunk) {
      console.log('Response: ' + chunk)
    });
  });

  // post the data
  request.write(data);
  request.end();
}

publish()
