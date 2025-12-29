const Post = require('../models/Post');
const fs = require('fs');
const path = require('path');

// 1. Create Post
const createPost = async (req, res) => {
  try {
    const newPost = new Post({
      description: req.body.description,
      // FIX: Use req.file.path to get the actual Cloudinary URL
      // Do NOT use localhost construction here.
      imageUrl: req.file ? req.file.path : "", 
      user: req.user.id,
    });
    
    const savedPost = await newPost.save();
    
    // Populate user details immediately
    await savedPost.populate('user', 'username profilePic');
    
    res.status(201).json(savedPost);
  } catch (err) {
    res.status(500).json(err);
  }
};

// 2. Get All Posts (Feed) 
const getAllPosts = async (req, res) => {
  try {
    const posts = await Post.find()
      .populate('user', 'username profilePic') // Populate Post Author
      .populate({
        path: 'comments.user', // Populate Comment Authors
        select: 'username profilePic' // Only get name and pic
      })
      .sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json(err);
  }
};

// 3. Get User's Posts (Profile) 
const getUserPosts = async (req, res) => {
  try {
    const posts = await Post.find({ user: req.params.userId })
      .populate('user', 'username profilePic')
      .populate({
        path: 'comments.user',
        select: 'username profilePic'
      })
      .sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json(err);
  }
};

// 4. Edit Post
const editPost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json("Post not found");
    
    // Check ownership
    if (post.user.toString() !== req.user.id) {
      return res.status(403).json("You can only update your own posts");
    }

    await post.updateOne({ $set: { description: req.body.description } });
    res.status(200).json("Post updated");
  } catch (err) {
    res.status(500).json(err);
  }
};

// 5. Delete Post
const deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json("Post not found");
    
    // Check ownership
    if (post.user.toString() !== req.user.id) {
      return res.status(403).json("You can only delete your own posts");
    }

    await post.deleteOne();
    res.status(200).json("Post deleted");
  } catch (err) {
    res.status(500).json(err);
  }
};

module.exports = {
  createPost,
  getAllPosts,
  getUserPosts,
  editPost,
  deletePost
};