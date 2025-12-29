const express = require('express');
const router = express.Router();
const Post = require('../models/Post');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware'); 
const { upload } = require('../middleware/uploadMiddleware'); 

const { 
    createPost, 
    getAllPosts, 
    deletePost, 
    getUserPosts, 
    editPost 
} = require('../controllers/postController');


// 1. Create Post (Image uploads to Cloudinary automatically via 'upload.single')
router.post('/', authMiddleware, upload.single('image'), createPost);

// 2. Get All Posts (Feed)
router.get('/', authMiddleware, getAllPosts);

// 3. Get User's Posts (Profile)
router.get('/user/:userId', authMiddleware, getUserPosts);

// 4. Edit Post (Description only)
router.put('/:id', authMiddleware, editPost);

// 5. Delete Post
router.delete('/:id', authMiddleware, deletePost);

// 6. Like / Unlike a Post
router.put('/:id/like', authMiddleware, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json("Post not found");

    // Check if post is already liked by this user
    if (!post.likes.includes(req.user.id)) {
      // Like
      await post.updateOne({ $push: { likes: req.user.id } });
      res.status(200).json("The post has been liked");
    } else {
      // Unlike
      await post.updateOne({ $pull: { likes: req.user.id } });
      res.status(200).json("The post has been unliked");
    }
  } catch (err) {
    console.error("Like Error:", err);
    res.status(500).json(err);
  }
});

// 7. Add a Comment
router.post('/:id/comment', authMiddleware, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json("Post not found");

    // --- ROBUST USERNAME FETCHING ---
    // If authMiddleware didn't attach username, fetch it from DB
    let username = req.user.username;
    if (!username) {
        const user = await User.findById(req.user.id);
        username = user ? user.username : "Unknown";
    }

    const newComment = {
      user: req.user.id,
      username: username, // Saved so frontend displays it immediately
      text: req.body.text,
      createdAt: new Date()
    };

    await post.updateOne({ $push: { comments: newComment } });
    res.status(200).json(newComment); 
  } catch (err) {
    console.error("Comment Error:", err);
    res.status(500).json(err);
  }
});

module.exports = router;