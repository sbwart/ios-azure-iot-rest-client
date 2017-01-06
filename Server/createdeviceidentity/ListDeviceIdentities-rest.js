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

var hostname = 'IoTPOCGateway';
var apiversion = '2016-02-03';
var endpoint =`${hostname}.azure-devices.net/devices`;
var devicekey = 'dEwJc/FoqoNKWyziMuRwM9jpBR29ZTZg1Klxzec58mA=';
var policyName = 'iothubowner';
var token = generateSasToken(endpoint, devicekey, policyName, 60);
var top = 1000;

var options = {
  host: `${hostname}.azure-devices.net`,
  path: `/devices?top=${top}&api-version=${apiversion}`,
  method: 'GET',
  headers: {
    'Authorization': token
  }
};

function publish() {
  var request = https.request(options, function(res) {
    res.setEncoding('utf8');
    res.on('data', function(chunk) {
      // XXX this won't work with large results and we should wait for the session to close
      // However this should be suitable for simple test scripts
      var result = JSON.parse(chunk);
      console.log(result);
    });
  });
  request.end();
}

publish()
