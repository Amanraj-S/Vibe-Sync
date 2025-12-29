class ImageUtils {
  // ⚠️ REPLACE 'devq3zfrq' WITH YOUR ACTUAL CLOUDINARY CLOUD NAME IF DIFFERENT
  static String getValidImageUrl(String url) {
    if (url.isEmpty) return "";

    // 1. Rescue broken Cloudinary links (missing domain)
    if (url.contains("vibesync_posts") || url.contains("vibesync")) {
      String cleanId = url.split(RegExp(r'vibesync(?:_posts)?/')).last;
      return "https://res.cloudinary.com/devq3zfrq/image/upload/vibesync_posts/$cleanId";
    }

    // 2. Standard URL Handling
    if (url.startsWith("http") || url.startsWith("https")) {
      // FIX: If database has 'localhost', swap it for Render URL
      if (url.contains("localhost")) {
        return url.replaceFirst("http://localhost:5000", "https://vibe-sync-ijgt.onrender.com");
      }
      return url;
    }

    // 3. Handle relative paths (e.g., "uploads/image.png")
    return "https://vibe-sync-ijgt.onrender.com/$url";
  }
}