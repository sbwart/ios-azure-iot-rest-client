var config = {}

config.host = process.env.HOST || "https://itpocdocdb.documents.azure.com:443/";
config.authKey = process.env.AUTH_KEY || "vKRkqesPqth0wGUBPby609ljKHGNEbKiGIOKPUPIXhGd8WHKDLwrWelCAtGvj1ULqYiKe0sMDVeVPdLJEZab2A==";
config.databaseId = "ToDoList";
config.collectionId = "Items";

module.exports = config;