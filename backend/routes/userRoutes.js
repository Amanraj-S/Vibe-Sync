const express = require('express');
const { 
    getAllUsers, 
    followUser, 
    updateProfile, 
    getUserProfile, 
    getUserConnections, 
    deleteAccount 
} = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const { upload } = require('../middleware/uploadMiddleware'); 
const router = express.Router();

// 1. Search Users (Get All)
// GET /api/users
router.get('/', authMiddleware, getAllUsers);

// 2. Follow / Unfollow User
// PUT /api/users/follow/:id
router.put('/follow/:id', authMiddleware, followUser);

// 3. Update Profile (About & Profile Pic)
// PUT /api/users/update
router.put('/update', authMiddleware, upload.single('profilePic'), updateProfile);

// 4. Get User Profile by ID (Visit other profiles)
// GET /api/users/profile/:id
router.get('/profile/:id', authMiddleware, getUserProfile);

// 5. Get Followers & Following List
// GET /api/users/connections/:id
router.get('/connections/:id', authMiddleware, getUserConnections);

// 6. Delete My Account
// DELETE /api/users/delete
router.delete('/delete', authMiddleware, deleteAccount);

module.exports = router;