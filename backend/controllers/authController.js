const User = require('../models/User');
const bcrypt = require('bcryptjs'); // or 'bcrypt' depending on what you installed
const jwt = require('jsonwebtoken');

// REGISTER
exports.register = async (req, res) => {
    try {
        // 1. Destructure fields from the request body
        // 'about' comes from the text fields in your Flutter app
        const { username, email, password, about } = req.body;
        
        let profilePic = "";

        // 2. Check if an image file was uploaded (handled by Multer/Cloudinary)
        if (req.file) {
            profilePic = req.file.path; // Cloudinary returns the URL in 'path'
        }

        // 3. Check if user already exists
        let existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "User already exists" });
        }

        // 4. Hash the password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 5. Create the new User object
        const newUser = new User({
            username,
            email,
            password: hashedPassword,
            about: about || "", 
            profilePic: profilePic || "", // Store the image URL
        });

        // 6. Save to Database
        const savedUser = await newUser.save();

        // 7. Respond with success
        res.status(201).json(savedUser);
    } catch (err) {
        console.error("Registration Error:", err);
        res.status(500).json({ error: err.message });
    }
};

// LOGIN
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // 1. Check if user exists
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: "User not found" });

        // 2. Validate password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

        // 3. Create JWT Token
        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET);

        // 4. Send response (exclude password for security)
        const { password: _, ...userData } = user._doc;
        res.json({ token, user: userData });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};