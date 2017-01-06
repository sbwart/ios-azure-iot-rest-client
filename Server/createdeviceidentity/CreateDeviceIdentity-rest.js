'use strict';

// Use HTTP directly instead of Azure libraries
var https = require('https');
var crypto = require('crypto');

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

// create key of 20 random 32-bit values
function generate() {
    var key = "SW-"
    var alphabet = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
                    "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "X", "Y", "Z"]
    for (var i = 0; i < 20; i++) {
        var index = Math.floor(Math.random() * 32)
        key += alphabet[index]  
    }
    return key
}

var deviceid = generate();

var hostname = 'IoTPOCGateway';
var apiversion = '2016-02-03';
var endpoint =`${hostname}.azure-devices.net/devices`;
var devicekey = 'dEwJc/FoqoNKWyziMuRwM9jpBR29ZTZg1Klxzec58mA=';
var policyName = 'iothubowner';
var token = generateSasToken(endpoint, devicekey, policyName, 60);

var options = {
  host: `${hostname}.azure-devices.net`,
  path: `/devices/${deviceid}?api-version=${apiversion}`,
  method: 'PUT',
  headers: {
    'Authorization': token,
    'Content-Type': 'application/json', // this is required for this case or it will fail with a 500 Internal Server Error
    'If-None-Match': '*'  // will fail with 412 if resource already exists
  }
};

function submit() {
  var parameters = {
    deviceId: deviceid
  }

  var data = JSON.stringify(parameters);
  console.log("writing data: ", data);
  
  console.log("sending request with options", options);
  var request = https.request(options, function(res) {
    console.log('Response: ' + res.statusCode + ': ' + res.statusMessage);
    res.setEncoding('utf8');
    res.on('data', function(chunk) {

      console.log('Response: ' + chunk)

// Response: {"deviceId":"SW-ZY3D493E5E1Z101LXH5M","generationId":"636192417313416032","etag":"MA==","connectionState":"Disconnected","status":"enabled","statusReason":null,
// "connectionStateUpdatedTime":"0001-01-01T00:00:00","statusUpdatedTime":"0001-01-01T00:00:00","lastActivityTime":"0001-01-01T00:00:00","cloudToDeviceMessageCount":0,
// "authentication":{"symmetricKey":{"primaryKey":"lmxqfmfyNcvFMOb58F8aSjBDzrcIeTHXN3MNrCO6TOM=","secondaryKey":"BXuJS/YKjykq7jW0Ya/dGI6YA0pf39nn+vZT/AaABBs="},"x509Thumbprint":null}}

      var device = JSON.parse(chunk);
      console.log("Device ID:", device.deviceId);
      console.log("Device Primary Key:", device.authentication.symmetricKey.primaryKey);
      console.log("Device Secondary Key:", device.authentication.symmetricKey.secondaryKey);

    });
  });

  // post the data
  request.write(data);
  request.end();
}

submit()
