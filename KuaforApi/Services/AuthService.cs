using KuaforApi.Models;
using KuaforApi.Data;
using BCrypt.Net;

namespace KuaforApi.Services
{
    public class AuthService
    {
        private readonly AppDbContext _context;

        public AuthService(AppDbContext context)
        {
            _context = context;
        }

        // Kullanıcı kaydı (Register)
        public bool Register(User user, string password)
        {
            // 1. Aynı email varsa kaydetme
            if (_context.Users.Any(u => u.Email == user.Email))
                return false;

            // 2. Şifreyi hash’le
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password);

            // 3. Kaydet
            _context.Users.Add(user);
            _context.SaveChanges();
            return true;
        }

        // Giriş yapma (Login)
        public User? Login(string email, string password)
        {
            var user = _context.Users.FirstOrDefault(u => u.Email == email);
            if (user == null)
                return null;

            // Şifreyi doğrula
            bool isValid = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
            return isValid ? user : null;
        }
    }
}
