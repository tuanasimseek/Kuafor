using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        [Authorize]
        [HttpGet("me")]
        public IActionResult GetProfile()
        {
            var email = User?.Identity?.Name;
            return Ok(new { Email = email, Message = "Token geçerli 🎉" });
        }
    }
}
