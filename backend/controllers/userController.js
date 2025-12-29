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

// 3. Update Profile (Username, About & Profile Pic)
exports.updateProfile = async (req, res) => {
    try {
        // Initialize update object
        const updates = {};

        // Explicitly check and assign fields to prevent unwanted updates
        if (req.body.username) {
            updates.username = req.body.username;
        }
        
        // Handle 'about' or 'desc' depending on what the frontend sends
        if (req.body.about) updates.about = req.body.about;
        if (req.body.desc) updates.about = req.body.desc; // Map desc to about if schemas differ

        // If an image file was uploaded (Cloudinary), save its secure URL
        if (req.file) {
            updates.profilePic = req.file.path;
        }

        // Perform the update
        const updatedUser = await User.findByIdAndUpdate(
            req.user.id,
            { $set: updates },
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

// 5. Get Followers & Following Details (UPDATED FOR CHAT LIST)
exports.getUserConnections = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        
        if (!user) return res.status(404).json({ message: "User not found" });

        // Fetch FULL details for all users in the 'following' list
        // This fixes the "String is not a subtype of Map" error in Flutter
        const followingList = await Promise.all(
            user.following.map((friendId) => {
                return User.findById(friendId).select('username profilePic isOnline lastSeen about');
            })
        );

        const followersList = await Promise.all(
            user.followers.map((friendId) => {
                return User.findById(friendId).select('username profilePic isOnline lastSeen about');
            })
        );

        // Filter out any nulls (in case a followed user was deleted)
        const validFollowing = followingList.filter(friend => friend !== null);
        const validFollowers = followersList.filter(friend => friend !== null);

        res.json({
            following: validFollowing, // Returns Objects, not Strings
            followers: validFollowers
        });
    } catch (err) {
        console.error("Connection Error:", err);
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