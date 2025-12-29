const User = require('../models/User');
const Post = require('../models/Post'); // Required to delete posts when deleting account

// 1. Get All Users (For Search & Discovery)
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find().select('-password');
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 2. Follow / Unfollow User
exports.followUser = async (req, res) => {
    if (req.user.id === req.params.id) {
        return res.status(400).json({ message: "Cannot follow yourself" });
    }

    try {
        const currentUser = await User.findById(req.user.id);
        const userToFollow = await User.findById(req.params.id);

        if (!userToFollow) return res.status(404).json({ message: "User not found" });

        // Check if already following
        if (!currentUser.following.includes(req.params.id)) {
            // FOLLOW logic
            await currentUser.updateOne({ $push: { following: req.params.id } });
            await userToFollow.updateOne({ $push: { followers: req.user.id } });
            res.json({ message: "User followed" });
        } else {
            // UNFOLLOW logic
            await currentUser.updateOne({ $pull: { following: req.params.id } });
            await userToFollow.updateOne({ $pull: { followers: req.user.id } });
            res.json({ message: "User unfollowed" });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 3. Update Profile (About & Profile Pic)
exports.updateProfile = async (req, res) => {
    try {
        const updates = { ...req.body };

        // If an image file was uploaded, save its path
        if (req.file) {
            updates.profilePic = req.file.path;
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.user.id,
            updates,
            { new: true } // Return the updated user data
        ).select('-password');

        res.json(updatedUser);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 4. Get User Profile by ID (For visiting other profiles)
exports.getUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.params.id).select('-password');
        if (!user) return res.status(404).json({ message: "User not found" });
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 5. Get Followers & Following Details (For the User List Screen)
exports.getUserConnections = async (req, res) => {
    try {
        const user = await User.findById(req.params.id)
            .populate('followers', 'username profilePic about')
            .populate('following', 'username profilePic about');
        
        if (!user) return res.status(404).json({ message: "User not found" });

        res.json({
            followers: user.followers,
            following: user.following
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 6. Delete User Account
exports.deleteAccount = async (req, res) => {
    try {
        const userId = req.user.id;
        
        // 1. Delete all posts by this user
        await Post.deleteMany({ user: userId });

        // 2. Remove this user from others' following/followers lists
        await User.updateMany(
            { $or: [{ followers: userId }, { following: userId }] },
            { $pull: { followers: userId, following: userId } }
        );

        // 3. Delete the user
        await User.findByIdAndDelete(userId);
        
        res.json({ message: "Account deleted successfully" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};