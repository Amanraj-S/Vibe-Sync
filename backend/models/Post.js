const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema({
  description: { 
    type: String 
  },
  imageUrl: { 
    type: String 
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // --- NEW FIELDS ---
  likes: [
    { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User' 
    }
  ],
  comments: [
    {
      user: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true 
      },
      text: { 
        type: String, 
        required: true 
      },
      createdAt: { 
        type: Date, 
        default: Date.now 
      }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('Post', PostSchema);