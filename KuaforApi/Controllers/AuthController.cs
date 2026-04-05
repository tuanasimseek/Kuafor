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

        public AuthController(AppDbContext context, AuthService authService)
        {
            _context = context;
            _authService = authService;
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
                "Admin"        => "Admin",
                _              => "Customer"
            };

            var user = new User
            {
                FullName = request.FullName,
                Email    = request.Email,
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
            var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Unauthorized(new { message = "E-posta veya şifre hatalı." });

            var token = _authService.GenerateJwtToken(user);

            return Ok(new
            {
                message = "Giriş başarılı!",
                user    = new { user.FullName, user.Email, user.Role },
                token
            });
        }

        [HttpPost("forgot-password")]
        public IActionResult ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
                return BadRequest(new { message = "E-posta zorunludur." });

            var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (user == null)
                return NotFound(new { message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı." });

            return Ok(new { message = "Şifre sıfırlama bağlantısı gönderildi (demo)." });
        }
    }

    public class RegisterRequest
    {
        public string  FullName       { get; set; } = string.Empty;
        public string  Email          { get; set; } = string.Empty;
        public string  Password       { get; set; } = string.Empty;
        public string  Role           { get; set; } = "Customer";
        public string? SalonName      { get; set; }
        public string? SalonAddress   { get; set; }
        public double? SalonLatitude  { get; set; }  // YENİ
        public double? SalonLongitude { get; set; }  // YENİ
    }

    public class LoginRequest
    {
        public string Email    { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }
}