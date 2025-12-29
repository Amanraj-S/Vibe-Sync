const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path'); // <--- IMPORT THIS
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const User = require('./models/User');
const Message = require('./models/Message');

// IMPORT ROUTES SAFELY
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const postRoutes = require('./routes/postRoutes'); 
const chatRoutes = require('./routes/chatRoutes');

dotenv.config();
connectDB();

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors());
app.use(express.json());

// --- CRITICAL FIX: Serve Uploaded Images ---
// This allows http://IP:5000/uploads/image.png to work on your phone
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); 
// -------------------------------------------

// --- DEBUGGING: Check if routes are loaded correctly ---
if (!authRoutes) console.error("❌ CRITICAL: authRoutes is missing!");
if (!userRoutes) console.error("❌ CRITICAL: userRoutes is missing!");
if (!postRoutes) console.error("❌ CRITICAL: postRoutes is missing!"); 
if (!chatRoutes) console.error("❌ CRITICAL: chatRoutes is missing!");
// -----------------------------------------------------

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes); 
app.use('/api/chat', chatRoutes);

// Socket.io Setup
const io = new Server(server, {
    cors: {
        origin: "*", 
        methods: ["GET", "POST"]
    }
});

let onlineUsers = new Map();

io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join', async (userId) => {
        if (!userId) return;
        onlineUsers.set(userId, socket.id);
        
        // Update DB
        await User.findByIdAndUpdate(userId, { isOnline: true });
        
        // 1. Tell everyone who is online list (General)
        io.emit('online-users', Array.from(onlineUsers.keys()));
        
        // 2. Tell everyone SPECIFICALLY that this user is now online (Real-time status)
        io.emit('user-online', userId); 
    });

    socket.on('send-message', async ({ senderId, receiverId, text }) => {
        try {
            const newMessage = new Message({ sender: senderId, receiver: receiverId, text });
            await newMessage.save();
            
            const receiverSocketId = onlineUsers.get(receiverId);
            if (receiverSocketId) {
                io.to(receiverSocketId).emit('receive-message', newMessage);
            }
        } catch (err) {
            console.error("Message Error:", err);
        }
    });

    socket.on('disconnect', async () => {
        let disconnectedUserId;
        for (let [userId, socketId] of onlineUsers.entries()) {
            if (socketId === socket.id) {
                disconnectedUserId = userId;
                onlineUsers.delete(userId);
                break;
            }
        }
        
        if (disconnectedUserId) {
            // Update DB
            await User.findByIdAndUpdate(disconnectedUserId, { isOnline: false, lastSeen: new Date() });
            
            // 1. Update list
            io.emit('online-users', Array.from(onlineUsers.keys()));
            
            // 2. Tell everyone SPECIFICALLY that this user went offline
            io.emit('user-offline', disconnectedUserId); 
        }
        console.log('User disconnected');
    });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));