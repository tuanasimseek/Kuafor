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

        // 📌 Kayıt Ol (Register)
        [HttpPost("register")]
        public IActionResult Register([FromBody] RegisterRequest request)
        {
            var user = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                Role = request.Role
            };

            bool result = _authService.Register(user, request.Password);

            if (!result)
                return BadRequest("Bu email adresiyle kayıtlı kullanıcı zaten var.");

            return Ok("Kayıt başarılı!");
        }

        // 📌 Giriş Yap (Login)
        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                  return Unauthorized("E-posta veya şifre hatalı.");

            var token = _authService.GenerateJwtToken(user);

            return Ok(new
            {
                message = "Giriş başarılı!",
                user = new { user.FullName, user.Email, user.Role },token=token 
            });
        }
    }

    // 🔹 DTO (Data Transfer Objects)
    public class RegisterRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Role { get; set; } = "Customer";
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
