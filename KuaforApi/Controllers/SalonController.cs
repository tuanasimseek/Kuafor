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

    [HttpGet]
    public async Task<IActionResult> GetSalons()
    {
        var salons = await _context.Salons
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description, s.ImageUrl, s.OwnerId
            })
            .ToListAsync();
        return Ok(salons);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetSalon(int id)
    {
        var salon = await _context.Salons
            .Where(s => s.Id == id)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description, s.ImageUrl, s.OwnerId
            })
            .FirstOrDefaultAsync();

        if (salon == null)
            return NotFound(new { message = "Salon bulunamadı." });

        // 1) Salona doğrudan bağlı hizmetler (SalonId'li, salon sahibinin eklediği)
        var salonServices = await _context.Services
            .Where(sv => sv.SalonId == id && sv.StylistId == null)
            .Select(sv => new ServiceDto
            {
                Id = sv.Id,
                Name = sv.Name,
                Price = sv.Price,
                DurationMinutes = sv.DurationMinutes,
                StylistName = null
            })
            .ToListAsync();

        // 2) Stilistin hem SalonId hem StylistId'si olan hizmetler
        //    (createStylistService artık salonId de gönderiyor)
        var stylistSalonServices = await _context.Services
            .Where(sv => sv.SalonId == id && sv.StylistId != null)
            .Join(
                _context.Users,
                sv => sv.StylistId,
                u => u.Id,
                (sv, u) => new ServiceDto
                {
                    Id = sv.Id,
                    Name = sv.Name,
                    Price = sv.Price,
                    DurationMinutes = sv.DurationMinutes,
                    StylistName = u.FullName
                }
            )
            .ToListAsync();

        // 3) Eski yöntem — sadece StylistId var, SalonId yok (Employee join ile)
        //    Geriye dönük uyumluluk için bırakıyoruz
        var employeeUserIds = await _context.Employees
            .Where(e => e.SalonId == id)
            .Select(e => e.UserId)
            .ToListAsync();

        var legacyStylistServices = await _context.Services
            .Where(sv =>
                sv.StylistId != null &&
                sv.SalonId == null && // SalonId yoksa (eski kayıtlar)
                employeeUserIds.Contains(sv.StylistId!.Value))
            .Join(
                _context.Users,
                sv => sv.StylistId,
                u => u.Id,
                (sv, u) => new ServiceDto
                {
                    Id = sv.Id,
                    Name = sv.Name,
                    Price = sv.Price,
                    DurationMinutes = sv.DurationMinutes,
                    StylistName = u.FullName
                }
            )
            .ToListAsync();

        var allServices = salonServices
            .Concat(stylistSalonServices)
            .Concat(legacyStylistServices)
            .ToList();

        return Ok(new {
            salon.Id,
            salon.Name,
            salon.Address,
            salon.Description,
            salon.ImageUrl,
            salon.OwnerId,
            services = allServices
        });
    }

    [HttpGet("owner/{ownerId}")]
    public async Task<IActionResult> GetSalonByOwner(int ownerId)
    {
        var salon = await _context.Salons
            .Where(s => s.OwnerId == ownerId)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description, s.ImageUrl, s.OwnerId
            })
            .FirstOrDefaultAsync();

        if (salon == null)
            return NotFound(new { message = "Bu kullanıcıya ait salon bulunamadı." });

        return Ok(salon);
    }

    // YENİ — stilistin çalıştığı salonu Employee tablosundan bulur
    [HttpGet("stylist/{stylistId}")]
    public async Task<IActionResult> GetSalonByStylist(int stylistId)
    {
        var employee = await _context.Employees
            .Where(e => e.UserId == stylistId)
            .FirstOrDefaultAsync();

        if (employee == null)
            return NotFound(new { message = "Bu stiliste ait salon bulunamadı." });

        var salon = await _context.Salons
            .Where(s => s.Id == employee.SalonId)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description, s.ImageUrl, s.OwnerId
            })
            .FirstOrDefaultAsync();

        if (salon == null)
            return NotFound(new { message = "Salon bulunamadı." });

        return Ok(salon);
    }

    [HttpPost]
    public async Task<IActionResult> CreateSalon([FromBody] Salon salon)
    {
        var ownerExists = await _context.Users.AnyAsync(u => u.Id == salon.OwnerId);
        if (!ownerExists)
            return BadRequest(new { message = "Kullanıcı bulunamadı." });

        _context.Salons.Add(salon);
        await _context.SaveChangesAsync();

        return Ok(new {
            salon.Id, salon.Name, salon.Address,
            salon.Description, salon.ImageUrl, salon.OwnerId
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSalon(int id)
    {
        var salon = await _context.Salons.FindAsync(id);
        if (salon == null)
            return NotFound(new { message = "Salon bulunamadı." });

        _context.Salons.Remove(salon);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Salon silindi." });
    }
}

public class ServiceDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }
    public string? StylistName { get; set; }
}