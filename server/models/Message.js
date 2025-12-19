const mongoose = require('mongoose');
const MessageSchema = new mongoose.Schema({
  roomId: String, // Critical for 1-on-1 history
  senderId: String,
  text: String,
  createdAt: { type: Date, default: Date.now }
});
module.exports = mongoose.model('Message', MessageSchema);