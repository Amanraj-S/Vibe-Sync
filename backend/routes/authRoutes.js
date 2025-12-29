const express = require('express');
const { register, login } = require('../controllers/authController');
const { upload } = require('../config/cloudinary'); 
const router = express.Router();

// 1. Register User (Now supports Profile Picture upload)
// 'upload.single' processes the file named 'profilePic' coming from the frontend
router.post('/register', upload.single('profilePic'), register);

// 2. Login User
router.post('/login', login);

module.exports = router;