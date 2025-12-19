const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  username: { type: String, required: true },
  userAvatar: { type: String, default: "" },
  mediaUrl: { type: String, required: true },
  caption: { type: String, default: "" },
  likes: { type: [String], default: [] },
  
  // ✅ STRUCTURED COMMENT SCHEMA
  comments: [
    {
      userId: String,       // ID of person who commented
      username: String,     // Name of person
      userAvatar: String,   // Picture of person
      text: String,         // The comment text
      createdAt: { type: Date, default: Date.now }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.models.Post || mongoose.model('Post', PostSchema);