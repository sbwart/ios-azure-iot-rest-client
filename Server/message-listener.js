'use strict';

var EventHubClient = require('azure-event-hubs').Client,
    Connection = require('tedious').Connection,
    winston = require('winston');

var config = require(process.env.WEBROOT_PATH + '/scripts/config/config.js');
var connectionString = config.iothub_connectionString;

// set up logging
var log = new winston.Logger({
  transports: [
    new winston.transports.File({
        level: 'info',
        filename: process.env.WEBROOT_PATH + '/logs/message-listener.log',
        handleExceptions: true,
        json: false,
        maxsize: 5242880, //5MB
        maxFiles: 5,
        colorize: false
    }),
    new winston.transports.Console({
        level: 'debug',
        handleExceptions: true,
        json: false,
        colorize: true
    })
  ],
  exitOnError: false
});

function logMessage(message) {
  log.info('Message received: ' + JSON.stringify(message.body));
};

function logError(err) {
  log.error(err);
}

var Request = require('tedious').Request
var TYPES = require('tedious').TYPES;

// start listening for messages
startEventListener();

// TODO message may be an object or an array of objects (userId to be added)
/*
 {"timestamp":1484666426.48161,"device":"TM-MNBC0VB0ZX7GZLAC7LQ9","latitude":37.3899935168547,"longitude":-121.925106411257}
 */

function saveMessage(message) {
  logMessage(message);

  var connection = new Connection(config.database);
  connection.on('connect', function(err) {
    if (err) {
      logError(err);
    }
    else {
      var request = new Request("INSERT INTO Message (timestamp, deviceId, latitude, longitude, userId) VALUES (@timestamp, @deviceId, @latitude, @longitude, @userId);", function(err) {
        if (err) {
          log.error(err)
        }
      });
      request.addParameter('timestamp', TYPES.NVarChar, message.body.timestamp);
      request.addParameter('deviceId', TYPES.NVarChar , message.body.device);
      request.addParameter('latitude', TYPES.Float, message.body.latitude);
      request.addParameter('longitude', TYPES.Float, message.body.longitude);
      request.addParameter('userId', TYPES.NVarChar , message.body.userId);
      request.on('done', function (rowCount, more, rows) {
        if (!more) {
          // we may receive multiple 'done' events if there is more than one statement to process
          connection.close();
        }
      });
      connection.execSql(request);
    }
  });
}

function startEventListener() {
  log.info(" === Message Listener Service starting at " + new Date() + " ===");

  var client = EventHubClient.fromConnectionString(connectionString);
  client.open()
  .then(client.getPartitionIds.bind(client))
  .then(function (partitionIds) {
      return partitionIds.map(function (partitionId) {
          return client.createReceiver('$Default', partitionId, { 'startAfterTime' : Date.now()}).then(function(receiver) {
              log.info('Created partition receiver: ' + partitionId)
              receiver.on('errorReceived', logError);
              receiver.on('message', saveMessage);
          });
      });
  })
  .catch(logError);
}
