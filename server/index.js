require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const bcrypt = require('bcryptjs'); 
const Message = require('./models/Message');
const Post = require('./models/Post');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

const MONGO_URI = "mongodb+srv://test:Test12345@taskmanager.vot4oox.mongodb.net/vibesync?retryWrites=true&w=majority&appName=vibesync";

mongoose.connect(MONGO_URI)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.error('❌ DB Error:', err));

// ✅ UPDATED USER SCHEMA (Added following/followers)
const UserSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  avatar: { type: String, default: "" },
  bio: { type: String, default: "" },
  isOnline: { type: Boolean, default: false },
  lastSeen: { type: Date, default: Date.now },
  following: { type: Array, default: [] }, // List of IDs I follow
  followers: { type: Array, default: [] }  // List of IDs following me
}, { timestamps: true });

const User = mongoose.model("User", UserSchema);

// --- ROUTES ---

// 1. REGISTER
app.post('/register', async (req, res) => {
  const { username, password, avatar, bio } = req.body;
  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) return res.status(400).json({ error: "Username taken" });
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({ username, password: hashedPassword, avatar, bio });
    res.json(user);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 2. LOGIN
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: "User not found" });
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ error: "Invalid credentials" });
    await User.findByIdAndUpdate(user._id, { isOnline: true });
    // Fetch fresh data (including following array)
    const freshUser = await User.findById(user._id); 
    res.json(freshUser);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 3. UPDATE USER
app.put('/users/:id', async (req, res) => {
  try {
    const updatedUser = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedUser);
  } catch(e) { res.status(500).json({ error: "Update failed" }); }
});

// ✅ 4. FOLLOW / UNFOLLOW USER (New Route)
app.put('/users/:id/follow', async (req, res) => {
    if (req.body.userId !== req.params.id) {
      try {
        const targetUser = await User.findById(req.params.id);
        const currentUser = await User.findById(req.body.userId);

        if (!targetUser.followers.includes(req.body.userId)) {
          // FOLLOW LOGIC
          await targetUser.updateOne({ $push: { followers: req.body.userId } });
          await currentUser.updateOne({ $push: { following: req.params.id } });
          const updatedCurrentUser = await User.findById(req.body.userId); // Return updated user to frontend
          res.status(200).json(updatedCurrentUser);
        } else {
          // UNFOLLOW LOGIC
          await targetUser.updateOne({ $pull: { followers: req.body.userId } });
          await currentUser.updateOne({ $pull: { following: req.params.id } });
          const updatedCurrentUser = await User.findById(req.body.userId); // Return updated user
          res.status(200).json(updatedCurrentUser);
        }
      } catch (err) {
        res.status(500).json(err);
      }
    } else {
      res.status(403).json("You cant follow yourself");
    }
});

// 5. GET USERS (Keep existing logic)
app.get('/users', async (req, res) => {
  try { const users = await User.find({}, '-password'); res.json(users); } 
  catch(e) { res.status(500).json({ error: "Failed" }); }
});

// 6. GET POSTS
app.get('/posts', async (req, res) => {
  try { const posts = await Post.find().sort({ createdAt: -1 }); res.json(posts); } 
  catch (e) { res.status(500).json({ error: e.message }); }
});

// 7. CREATE POST
app.post('/posts', async (req, res) => {
  try { const newPost = await Post.create(req.body); res.json(newPost); } 
  catch(e) { res.status(500).json({ error: e.message }); }
});

// 8. LIKE POST
app.put('/posts/:id/like', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post.likes.includes(req.body.userId)) { await post.updateOne({ $push: { likes: req.body.userId } }); } 
    else { await post.updateOne({ $pull: { likes: req.body.userId } }); }
    res.status(200).json("Success");
  } catch (err) { res.status(500).json(err); }
});

// 9. COMMENT
app.post('/posts/:id/comment', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    const user = await User.findById(req.body.userId);
    const newComment = { userId: user._id, username: user.username, userAvatar: user.avatar, text: req.body.text, createdAt: new Date() };
    await post.updateOne({ $push: { comments: newComment } });
    res.status(200).json(newComment);
  } catch (err) { res.status(500).json(err); }
});

// 10. EDIT POST
app.put('/posts/:id', async (req, res) => {
  try { const updatedPost = await Post.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true }); res.status(200).json(updatedPost); } 
  catch (err) { res.status(500).json(err); }
});

// 11. DELETE POST
app.delete('/posts/:id', async (req, res) => {
  try { await Post.findByIdAndDelete(req.params.id); res.status(200).json("Deleted"); } 
  catch (err) { res.status(500).json(err); }
});

// 12. DELETE ACCOUNT
app.delete('/users/:id', async (req, res) => {
  try { await User.findByIdAndDelete(req.params.id); await Post.deleteMany({ userId: req.params.id }); res.status(200).json("Deleted"); } 
  catch (err) { res.status(500).json(err); }
});

// 13. MESSAGES
app.get('/messages/:roomId', async (req, res) => {
  const messages = await Message.find({ roomId: req.params.roomId }).sort({ createdAt: 1 });
  res.json(messages);
});

// --- SOCKET.IO ---
const onlineUsers = new Map();
io.on('connection', (socket) => {
  socket.on('register_user', async (userId) => {
    onlineUsers.set(socket.id, userId);
    await User.findByIdAndUpdate(userId, { isOnline: true });
    io.emit('user_status', { userId, status: 'Online', isOnline: true });
  });
  socket.on('join_room', (roomId) => { socket.join(roomId); });
  socket.on('typing', (roomId) => { socket.to(roomId).emit('display_typing', { isTyping: true, senderId: socket.id }); });
  socket.on('stop_typing', (roomId) => { socket.to(roomId).emit('display_typing', { isTyping: false, senderId: socket.id }); });
  socket.on('send_message', async (data) => {
    try { const msg = await Message.create(data); io.to(data.roomId).emit('receive_message', msg); } catch(e) {}
  });
  socket.on('disconnect', async () => {
    const userId = onlineUsers.get(socket.id);
    if (userId) {
      const lastSeenTime = new Date();
      await User.findByIdAndUpdate(userId, { isOnline: false, lastSeen: lastSeenTime });
      io.emit('user_status', { userId, lastSeen: lastSeenTime, status: 'Offline', isOnline: false });
      onlineUsers.delete(socket.id);
    }
  });
});

server.listen(3000, () => console.log('🚀 Server running on port 3000'));