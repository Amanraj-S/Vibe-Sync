class ImageUtils {
  static String getValidImageUrl(String url) {
    if (url.isEmpty) return "";

    // 1. If it's already a full web URL (starts with http/https)
    if (url.startsWith("http") || url.startsWith("https")) {
      // Only fix localhost for Android Emulators
      if (url.contains("localhost")) {
        return url.replaceFirst("http://localhost:5000", "https://vibe-sync-ijgt.onrender.com");
      }
      return url; // Trust the URL
    }

    // 2. RESCUE LOGIC: If the path contains "vibesync_posts", it is DEFINITELY a Cloudinary image
    // that got saved as a relative path. We must reconstruct the full Cloudinary URL.
    if (url.contains("vibesync_posts")) {
       // Extract the actual filename/ID from the path
       // e.g. "uploads/vibesync_posts/abc.jpg" -> "abc.jpg"
       String cleanId = url.split('/').last; 
       
       // Construct the Cloudinary URL.
       // IMPORTANT: Ensure 'devq3zfrq' is YOUR Cloudinary Cloud Name.
       // If your cloud name is different, change it here.
       return "https://res.cloudinary.com/devq3zfrq/image/upload/vibesync_posts/$cleanId";
    }

    // 3. Fallback: Assume it's a static file on the server (might fail on Render)
    return "https://vibe-sync-ijgt.onrender.com/$url";
  }
}