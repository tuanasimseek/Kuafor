using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using KuaforApi.Data;
using BCrypt.Net;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;

        public UsersController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        [Authorize]
        [HttpGet("me")]
        public IActionResult GetProfile()
        {
            var email = User?.Identity?.Name;
            if (string.IsNullOrEmpty(email))
                return Unauthorized(new { message = "Token geçersiz." });

            var user = _context.Users.FirstOrDefault(u => u.Email == email);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı." });

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            var imageUrl = user.ProfileImageUrl;
            if (!string.IsNullOrEmpty(imageUrl) && imageUrl.StartsWith("/"))
                imageUrl = $"{baseUrl}{imageUrl}";

            return Ok(new
            {
                id = user.Id,
                fullName = user.FullName,
                email = user.Email,
                role = user.Role,
                profileImageUrl = imageUrl ?? ""
            });
        }

        [Authorize]
        [HttpPut("update")]
        public IActionResult UpdateProfile([FromBody] UpdateUserRequest request)
        {
            var email = User?.Identity?.Name;
            if (string.IsNullOrEmpty(email))
                return Unauthorized(new { message = "Token geçersiz." });

            var user = _context.Users.FirstOrDefault(u => u.Email == email);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı." });

            if (!string.IsNullOrWhiteSpace(request.FullName))
                user.FullName = request.FullName.Trim();

            if (!string.IsNullOrWhiteSpace(request.Password))
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            _context.SaveChanges();

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            var imageUrl = user.ProfileImageUrl;
            if (!string.IsNullOrEmpty(imageUrl) && imageUrl.StartsWith("/"))
                imageUrl = $"{baseUrl}{imageUrl}";

            return Ok(new
            {
                message = "Profil güncellendi.",
                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    role = user.Role,
                    profileImageUrl = imageUrl ?? ""
                }
            });
        }

        [Authorize]
        [HttpPost("upload-photo")]
        public async Task<IActionResult> UploadPhoto(IFormFile file)
        {
            var email = User?.Identity?.Name;
            if (string.IsNullOrEmpty(email))
                return Unauthorized(new { message = "Token geçersiz." });

            var user = _context.Users.FirstOrDefault(u => u.Email == email);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı." });

            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Dosya boş." });

            var allowed = new[] { "image/jpeg", "image/png", "image/webp", "image/jpg" };
            if (!allowed.Contains(file.ContentType.ToLower()))
                return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz." });

            if (file.Length > 5 * 1024 * 1024)
                return BadRequest(new { message = "Dosya 5MB'dan büyük olamaz." });

            // _env.WebRootPath yerine sabit path — her zaman çalışır
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "profiles");
            Directory.CreateDirectory(uploadsFolder);

            // Eski fotoğrafı sil
            if (!string.IsNullOrEmpty(user.ProfileImageUrl))
            {
                var oldFileName = Path.GetFileName(new Uri(user.ProfileImageUrl).LocalPath);
                var oldPath = Path.Combine(uploadsFolder, oldFileName);
                if (System.IO.File.Exists(oldPath))
                    System.IO.File.Delete(oldPath);
            }

            var ext = Path.GetExtension(file.FileName).ToLower();
            if (string.IsNullOrEmpty(ext)) ext = ".jpg";
            var fileName = $"{user.Id}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}{ext}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
                await file.CopyToAsync(stream);

            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            var fullUrl = $"{baseUrl}/uploads/profiles/{fileName}";
            user.ProfileImageUrl = fullUrl;
            _context.SaveChanges();

            return Ok(new
            {
                message = "Fotoğraf yüklendi.",
                profileImageUrl = fullUrl
            });
        }
    }

    public class UpdateUserRequest
    {
        public string? FullName { get; set; }
        public string? Password { get; set; }
    }
}