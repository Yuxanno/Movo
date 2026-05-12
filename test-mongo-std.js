const mongoose = require('mongoose');

// Testing standard connection string (no SRV)
const MONGODB_URI = "mongodb://moliya33w_db_user:7VHZ2F5PEBbMJSub@ac-lsxpiyk-shard-00-00.qnzxsgd.mongodb.net:27017,ac-lsxpiyk-shard-00-01.qnzxsgd.mongodb.net:27017,ac-lsxpiyk-shard-00-02.qnzxsgd.mongodb.net:27017/?authSource=admin&replicaSet=atlas-lsxpiyk-shard-0&tls=true";

async function test() {
  try {
    console.log("Connecting with standard URI...");
    await mongoose.connect(MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 10000,
    });
    console.log("Connected to MongoDB!");
    process.exit(0);
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
}

test();
