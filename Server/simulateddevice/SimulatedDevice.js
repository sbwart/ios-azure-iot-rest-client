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

var hostname = 'IoTPOCGateway';
var deviceid = 'ngscFirstNodeDevice';
var endpoint = `${hostname}.azure-devices.net/devices/${deviceid}`;
// var devicekey = 'PcMGegjfmDhD/YSD+NZmUXavNa4T5BnydISX8ci4rO0=';  // primary key for ngscFirstNodeDevice
var devicekey = 'wA18wu4ERemxetPFcavCZcG+Mb67t7zuUc6yl0yirCI=';   // device

var token = generateSasToken(endpoint, devicekey, 'device', 60);

var windSpeed = 10 + (Math.random() * 4);
var data = JSON.stringify({deviceId: deviceid, windSpeed: windSpeed});

var options = {
  host: `${hostname}.azure-devices.net`,
  path: `/devices/${deviceid}/messages/events?api-version=2016-02-03`,
  method: 'POST',
  headers: {
    'Authorization': token
  }
};

var request = https.request(options, function(res) {
  res.setEncoding('utf8');
  res.on('data', function(chunk) {
    console.log('Response: ' + chunk)
  });
});

// post the data
request.write(data);
request.end();


function testHmac(stringValue) {
  var hmac = crypto.createHmac('sha256', new Buffer(devicekey, 'base64'));
  hmac.update(stringValue);
  return encodeURIComponent(hmac.digest('base64'));
}

console.log("hmac(abc)=", testHmac("abc"))