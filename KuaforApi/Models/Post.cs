using System;
using System.Collections.Generic;

namespace KuaforApi.Models
{
    public class Post
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Category { get; set; } = "Genel"; // "BeforeAfter", "Genel", "Kampanya"
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public int SalonId { get; set; }
        public Salon? Salon { get; set; }
        public List<PostImage> Images { get; set; } = new();
    }

    public class PostImage
    {
        public int Id { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string? Tag { get; set; }  // "before", "after", null
        public int Order { get; set; } = 0;
        public int PostId { get; set; }
        public Post? Post { get; set; }
    }
}