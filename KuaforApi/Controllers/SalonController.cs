using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SalonController : ControllerBase
{
    private readonly AppDbContext _context;

    public SalonController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/salon
    [HttpGet]
    public async Task<IActionResult> GetSalons()
    {
        var salons = await _context.Salons
            .Include(s => s.Owner)
            .ToListAsync();

        return Ok(salons);
    }

    // POST: api/salon
    [HttpPost]
    public async Task<IActionResult> CreateSalon(Salon salon)
    {
        // Owner var mı kontrol
        var ownerExists = await _context.Users.AnyAsync(u => u.Id == salon.OwnerId);
        if (!ownerExists)
            return BadRequest("Owner (User) bulunamadı");

        _context.Salons.Add(salon);
        await _context.SaveChangesAsync();

        return Ok(salon);
    }
}
