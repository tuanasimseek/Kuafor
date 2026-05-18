using KuaforApi.Data;
using Microsoft.AspNetCore.Mvc;
using KuaforApi.Models;
using KuaforApi.Services;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly AuthService _authService;
        private readonly EmailService _emailService;

        public AuthController(AppDbContext context, AuthService authService, EmailService emailService)
        {
            _context = context;
            _authService = authService;
            _emailService = emailService;
        }

        [HttpPost("register")]
        public IActionResult Register([FromBody] RegisterRequest request)
        {
            string normalizedRole = request.Role?.Trim() switch
            {
                "Müşteri"      => "Customer",
                "Customer"     => "Customer",
                "Kuaför"       => "Hairdresser",
                "Hairdresser"  => "Hairdresser",
                "Salon Sahibi" => "SalonOwner",
                "SalonOwner"   => "SalonOwner",
                _              => "Customer"
            };

            var user = new User
            {
                FullName = request.FullName,
                Email    = request.Email,
                Username = string.IsNullOrWhiteSpace(request.Username)
                    ? GenerateUsername(request.Email)
                    : request.Username.Trim(),
                Role     = normalizedRole
            };

            var success = _authService.Register(user, request.Password);
            if (!success)
                return BadRequest(new { message = "Bu e-posta zaten kayıtlı." });

            var savedUser = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (savedUser == null)
                return StatusCode(500, new { message = "Kullanıcı kaydedilemedi." });

            if (normalizedRole == "SalonOwner")
            {
                var salonName    = string.IsNullOrWhiteSpace(request.SalonName)
                    ? $"{request.FullName} Salonu"
                    : request.SalonName;
                var salonAddress = string.IsNullOrWhiteSpace(request.SalonAddress)
                    ? ""
                    : request.SalonAddress;

                var salon = new Salon
                {
                    Name        = salonName,
                    Address     = salonAddress,
                    Description = "",
                    OwnerId     = savedUser.Id,
                    Latitude    = request.SalonLatitude,   // YENİ
                    Longitude   = request.SalonLongitude,  // YENİ
                };
                _context.Salons.Add(salon);
                _context.SaveChanges();
            }

            return Ok(new { message = "Kayıt başarılı 🎉" });
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            var identifier = string.IsNullOrWhiteSpace(request.Identifier)
                ? request.Email
                : request.Identifier;

            var user = _context.Users.FirstOrDefault(u =>
                u.Email == identifier || u.Username == identifier);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Unauthorized(new { message = "E-posta/kullanıcı adı veya şifre hatalı." });

            var token = _authService.GenerateJwtToken(user);

            return Ok(new
            {
                message = "Giriş başarılı!",
                user    = new { user.FullName, user.Email, user.Role },
                token
            });
        }

        [HttpPost("social-login")]
        public IActionResult SocialLogin([FromBody] SocialLoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
                return BadRequest(new { message = "Sosyal giriş için e-posta alınamadı." });

            var provider = string.IsNullOrWhiteSpace(request.Provider)
                ? "Social"
                : request.Provider.Trim();

            var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (user == null)
            {
                user = new User
                {
                    FullName = string.IsNullOrWhiteSpace(request.FullName)
                        ? request.Email.Split('@')[0]
                        : request.FullName.Trim(),
                    Email = request.Email.Trim(),
                    Username = GenerateUsername(request.Email),
                    Role = "Customer",
                    AuthProvider = provider,
                    ProviderId = request.ProviderId,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N"))
                };
                _context.Users.Add(user);
                _context.SaveChanges();
            }

            var token = _authService.GenerateJwtToken(user);
            return Ok(new
            {
                message = $"{provider} ile giriş başarılı.",
                user = new { user.FullName, user.Email, user.Role },
                token
            });
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
                return BadRequest(new { message = "E-posta zorunludur." });

            var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (user == null)
                return NotFound(new { message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı." });

            if (!_emailService.IsConfigured)
                return Ok(new { message = "SMTP ayarı tanımlı değil. Demo modunda sıfırlama talebi alındı." });

            try
            {
                await _emailService.SendPasswordResetAsync(user.Email, user.FullName);
                return Ok(new { message = "Şifre sıfırlama e-postası gönderildi." });
            }
            catch
            {
                return StatusCode(500, new { message = "E-posta gönderilemedi. SMTP ayarlarını kontrol edin." });
            }
        }

        private static string GenerateUsername(string email)
        {
            var prefix = email.Split('@')[0]
                .ToLowerInvariant()
                .Replace(".", "")
                .Replace("_", "");
            return $"{prefix}{Random.Shared.Next(1000, 9999)}";
        }
    }

    public class RegisterRequest
    {
        public string  FullName       { get; set; } = string.Empty;
        public string  Email          { get; set; } = string.Empty;
        public string? Username       { get; set; }
        public string  Password       { get; set; } = string.Empty;
        public string  Role           { get; set; } = "Customer";
        public string? SalonName      { get; set; }
        public string? SalonAddress   { get; set; }
        public double? SalonLatitude  { get; set; }  // YENİ
        public double? SalonLongitude { get; set; }  // YENİ
    }

    public class LoginRequest
    {
        public string? Identifier { get; set; }
        public string Email    { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class SocialLoginRequest
    {
        public string Provider { get; set; } = string.Empty;
        public string ProviderId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }
}
