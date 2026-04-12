
const mongoose = require('mongoose');

const MONGODB_URI = "mongodb+srv://moliya33w_db_user:7VHZ2F5PEBbMJSub@cluster0.qnzxsgd.mongodb.net/";

async function test() {
  try {
    console.log("Connecting...");
    await mongoose.connect(MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      connectTimeoutMS: 10000,
      family: 4,
    });
    console.log("Connected to MongoDB!");
    process.exit(0);
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
}

test();
