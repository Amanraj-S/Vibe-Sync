const router = require("express").Router();
const Post = require("../models/Post");
const User = require("../models/User"); // ✅ Import User Model

// ... (Your Create and Get routes here) ...

// 1. GET ALL POSTS
router.get("/", async (req, res) => {
  try {
    const posts = await Post.find().sort({ createdAt: -1 }); // Newest first
    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json(err);
  }
});

// 2. CREATE POST
router.post("/", async (req, res) => {
  const newPost = new Post(req.body);
  try {
    const savedPost = await newPost.save();
    res.status(200).json(savedPost);
  } catch (err) {
    res.status(500).json(err);
  }
});

// 3. LIKE POST
router.put("/:id/like", async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post.likes.includes(req.body.userId)) {
      await post.updateOne({ $push: { likes: req.body.userId } });
      res.status(200).json("The post has been liked");
    } else {
      await post.updateOne({ $pull: { likes: req.body.userId } });
      res.status(200).json("The post has been disliked");
    }
  } catch (err) {
    res.status(500).json(err);
  }
});

// 4. ✅ ADD COMMENT ROUTE
router.post("/:id/comment", async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    // Find the user to get their avatar and name correctly
    const user = await User.findById(req.body.userId);

    const newComment = {
      userId: user._id,
      username: user.username,
      userAvatar: user.avatar, 
      text: req.body.text,
      createdAt: new Date()
    };

    await post.updateOne({ $push: { comments: newComment } });
    res.status(200).json(newComment);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;