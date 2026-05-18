using KuaforApi.Models;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using KuaforApi.Data;
using BCrypt.Net;

namespace KuaforApi.Services
{
    public class AuthService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthService(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // Kullanıcı kaydı (Register)
        public bool Register(User user, string password)
        {
            // 1. Aynı email varsa kaydetme
            if (_context.Users.Any(u => u.Email == user.Email))
                return false;

            if (!string.IsNullOrWhiteSpace(user.Username) &&
                _context.Users.Any(u => u.Username == user.Username))
                return false;

            // 2. Şifreyi hash’le
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password);

            // 3. Kaydet
            _context.Users.Add(user);
            _context.SaveChanges();
            return true;
        }

        // Giriş yapma (Login)
        public User? Login(string identifier, string password)
        {
            var normalized = identifier.Trim();
            var user = _context.Users.FirstOrDefault(u =>
                u.Email == normalized || u.Username == normalized);
            if (user == null)
                return null;

            // Şifreyi doğrula
            bool isValid = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
            return isValid ? user : null;
        }

        // JWT Token oluşturma
        public string GenerateJwtToken(User user)
        {
            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Email),
                new Claim(ClaimTypes.Role, user.Role)
            };

            var jwtKey =
                Environment.GetEnvironmentVariable("Jwt__Key")
                ?? _configuration["Jwt:Key"];

            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                jwtKey = "this_is_a_very_strong_secret_key_1234567890";
            }

            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            );
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: "KuaforApi",
                audience: "KuaforApiClient",
                claims: claims,
                expires: DateTime.Now.AddHours(3),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
