const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    // 1. Get the token from the header
    const tokenHeader = req.header('Authorization');

    // 2. Check if no token is provided
    if (!tokenHeader) {
        return res.status(401).json({ message: "No token, authorization denied" });
    }

    try {
        // 3. Extract token (Handles both "Bearer <token>" and just "<token>")
        // This prevents errors if your frontend changes how it sends headers.
        const token = tokenHeader.replace('Bearer ', '').trim();

        // 4. Verify the token using your secret key
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 5. Attach the user payload (id) to the request object
        // This allows your controllers (like userController) to use 'req.user.id'
        req.user = decoded;

        // 6. Proceed to the next middleware or controller function
        next();
    } catch (err) {
        console.error("Auth Error:", err.message); 
        res.status(400).json({ message: "Token is not valid" });
    }
};