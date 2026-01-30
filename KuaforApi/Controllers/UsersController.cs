using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using KuaforApi.Data; // DbContext için
using System.Linq;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        [Authorize]
        [HttpGet("me")]
        public IActionResult GetProfile()
        {
            var email = User?.Identity?.Name;
            if (string.IsNullOrEmpty(email))
                return Unauthorized(new { Message = "Token geçersiz." });

            var user = _context.Users.FirstOrDefault(u => u.Email == email);
            if (user == null)
                return NotFound(new { Message = "Kullanıcı bulunamadı." });

            return Ok(new
            {
                FullName = user.FullName,
                Email = user.Email,
                Role = user.Role
            });
        }
    }
}
