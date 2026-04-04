using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ServiceController : ControllerBase
{
    private readonly AppDbContext _context;

    public ServiceController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonServices(int salonId)
    {
        var services = await _context.Services
            .Where(s => s.SalonId == salonId)
            .ToListAsync();
        return Ok(services);
    }

    [HttpGet("stylist/{stylistId}")]
    public async Task<IActionResult> GetStylistServices(int stylistId)
    {
        var services = await _context.Services
            .Where(s => s.StylistId == stylistId)
            .ToListAsync();
        return Ok(services);
    }

    [HttpPost]
    public async Task<IActionResult> CreateService([FromBody] Service service)
    {
        // SalonId geliyorsa ve geçerliyse salon kontrolü yap
        if (service.SalonId.HasValue && service.SalonId.Value > 0)
        {
            var salonExists = await _context.Salons.AnyAsync(s => s.Id == service.SalonId.Value);
            if (!salonExists)
                return BadRequest(new { message = "Salon bulunamadı" });
        }

        // StylistId geliyorsa kullanıcı kontrolü yap
        if (service.StylistId.HasValue && service.StylistId.Value > 0)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == service.StylistId.Value);
            if (!userExists)
                return BadRequest(new { message = "Stilist bulunamadı" });
        }

        // En az biri zorunlu
        if ((!service.SalonId.HasValue || service.SalonId.Value == 0) &&
            (!service.StylistId.HasValue || service.StylistId.Value == 0))
        {
            return BadRequest(new { message = "SalonId veya StylistId zorunlu" });
        }

        _context.Services.Add(service);
        await _context.SaveChangesAsync();
        return Ok(service);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateService(int id, [FromBody] Service service)
    {
        var existing = await _context.Services.FindAsync(id);
        if (existing == null)
            return NotFound(new { message = "Hizmet bulunamadı" });

        existing.Name = service.Name;
        existing.Price = service.Price;
        existing.DurationMinutes = service.DurationMinutes;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteService(int id)
    {
        var service = await _context.Services.FindAsync(id);
        if (service == null)
            return NotFound(new { message = "Hizmet bulunamadı" });

        _context.Services.Remove(service);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}