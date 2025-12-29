const express = require('express');
const { getMessages } = require('../controllers/chatController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();
if (!getMessages) {
    console.error("❌ CRITICAL ERROR: 'getMessages' is missing from chatController.js");
}
// GET /api/chat/:userId 
// Fetch conversation history with a specific user
router.get('/:userId', authMiddleware, getMessages);

module.exports = router;