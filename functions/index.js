const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// Trigger on Realtime Database changes
exports.onNoteChange = functions.database
  .instance()
  .ref("/notes/{noteId}")
  .onUpdate((change, context) => {
    // Retrieve the data before and after the update
    const beforeData = change.before.val();
    const afterData = change.after.val();
    
    // Do something with the data, for example:



    // Perform any other action, like sending a push notification
    // For instance, you can check if comments or likes have changed
    if (afterData.likes !== beforeData.likes) {
      console.log("Likes updated!");
    }

    return null; // or return a promise if you're doing async operations
  });

Object.assign(exports, require("./wellness"));

Object.assign(exports, require("./collaboration"));
