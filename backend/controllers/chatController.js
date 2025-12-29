const Message = require('../models/Message');

// Get chat history between the current user (req.user.id) and another user (req.params.userId)
exports.getMessages = async (req, res) => {
    try {
        const { userId } = req.params; // The ID of the person you are chatting with
        const myId = req.user.id;      // Your ID from the auth token

        // Find messages where:
        // 1. I am sender AND they are receiver
        // OR
        // 2. They are sender AND I am receiver
        const messages = await Message.find({
            $or: [
                { sender: myId, receiver: userId },
                { sender: userId, receiver: myId }
            ]
        }).sort({ createdAt: 1 }); // Sort by oldest first

        res.json(messages);
    } catch (err) {
        console.error("Error fetching messages:", err.message);
        res.status(500).json({ error: "Server Error: Could not fetch chat history" });
    }
};