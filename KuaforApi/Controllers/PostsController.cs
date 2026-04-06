using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PostsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;

        public PostsController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // GET /api/Posts — tüm gönderiler (feed)
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var posts = await _context.Posts
                .Include(p => p.Salon)
                .Include(p => p.Images.OrderBy(i => i.Order))
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var result = posts.Select(p => MapToDto(p));
            return Ok(result);
        }

        // GET /api/Posts/salon/{salonId}
        [HttpGet("salon/{salonId}")]
        public async Task<IActionResult> GetBySalon(int salonId)
        {
            var posts = await _context.Posts
                .Include(p => p.Salon)
                .Include(p => p.Images.OrderBy(i => i.Order))
                .Where(p => p.SalonId == salonId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var result = posts.Select(p => MapToDto(p));
            return Ok(result);
        }

        // GET /api/Posts/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var post = await _context.Posts
                .Include(p => p.Salon)
                .Include(p => p.Images.OrderBy(i => i.Order))
                .FirstOrDefaultAsync(p => p.Id == id);

            if (post == null) return NotFound();
            return Ok(MapToDto(post));
        }

        // POST /api/Posts
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Create([FromBody] CreatePostDto dto)
        {
            var post = new Post
            {
                Title = dto.Title,
                Description = dto.Description,
                Category = dto.Category ?? "Genel",
                SalonId = dto.SalonId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Posts.Add(post);
            await _context.SaveChangesAsync();

            return Ok(new { post.Id, message = "Gönderi oluşturuldu" });
        }

        // POST /api/Posts/{id}/upload-image?tag=before&order=0
        [HttpPost("{id}/upload-image")]
        [Authorize]
        public async Task<IActionResult> UploadImage(int id, IFormFile file, [FromQuery] string? tag, [FromQuery] int order = 0)
        {
            var post = await _context.Posts.FindAsync(id);
            if (post == null) return NotFound();

            if (file == null || file.Length == 0)
                return BadRequest("Dosya bulunamadı");

            var uploadsPath = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "posts");
            Directory.CreateDirectory(uploadsPath);

            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var request = HttpContext.Request;
            var baseUrl = $"{request.Scheme}://{request.Host}";
            var imageUrl = $"{baseUrl}/uploads/posts/{fileName}";

            var postImage = new PostImage
            {
                PostId = id,
                ImageUrl = imageUrl,
                Tag = tag,
                Order = order
            };

            _context.PostImages.Add(postImage);
            await _context.SaveChangesAsync();

            return Ok(new { postImage.Id, imageUrl });
        }

        // DELETE /api/Posts/{id}/images/{imgId}
        [HttpDelete("{id}/images/{imgId}")]
        [Authorize]
        public async Task<IActionResult> DeleteImage(int id, int imgId)
        {
            var image = await _context.PostImages
                .FirstOrDefaultAsync(i => i.Id == imgId && i.PostId == id);

            if (image == null) return NotFound();

            // Fiziksel dosyayı sil
            try
            {
                var fileName = Path.GetFileName(new Uri(image.ImageUrl).LocalPath);
                var filePath = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "posts", fileName);
                if (System.IO.File.Exists(filePath))
                    System.IO.File.Delete(filePath);
            }
            catch { }

            _context.PostImages.Remove(image);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Fotoğraf silindi" });
        }

        // DELETE /api/Posts/{id}
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> Delete(int id)
        {
            var post = await _context.Posts
                .Include(p => p.Images)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (post == null) return NotFound();

            // Fiziksel dosyaları sil
            foreach (var image in post.Images)
            {
                try
                {
                    var fileName = Path.GetFileName(new Uri(image.ImageUrl).LocalPath);
                    var filePath = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "posts", fileName);
                    if (System.IO.File.Exists(filePath))
                        System.IO.File.Delete(filePath);
                }
                catch { }
            }

            _context.Posts.Remove(post);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gönderi silindi" });
        }

        // Helper: Post → DTO
        private object MapToDto(Post p)
        {
            return new
            {
                p.Id,
                p.Title,
                p.Description,
                p.Category,
                p.CreatedAt,
                p.SalonId,
                SalonName = p.Salon?.Name,
                Images = p.Images.Select(i => new
                {
                    i.Id,
                    i.ImageUrl,
                    i.Tag,
                    i.Order
                }).ToList()
            };
        }
    }

    public class CreatePostDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Category { get; set; }
        public int SalonId { get; set; }
    }
}