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
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude,
                averageRating = _context.Reviews
                    .Where(r => r.SalonId == s.Id)
                    .Select(r => (double?)r.Rating)
                    .Average() ?? 0
            })
            .ToListAsync();
        return Ok(salons);
    }

    [HttpGet("nearby")]
    public async Task<IActionResult> GetNearbySalons(
        [FromQuery] double lat,
        [FromQuery] double lng,
        [FromQuery] double radius = 10.0)
    {
        var salons = await _context.Salons
            .Where(s => s.Latitude != null && s.Longitude != null)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude,
                averageRating = _context.Reviews
                    .Where(r => r.SalonId == s.Id)
                    .Select(r => (double?)r.Rating)
                    .Average() ?? 0
            })
            .ToListAsync();

        var nearby = salons
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude,
                DistanceKm = HaversineDistance(lat, lng, s.Latitude!.Value, s.Longitude!.Value)
            })
            .Where(s => s.DistanceKm <= radius)
            .OrderBy(s => s.DistanceKm)
            .ToList();

        return Ok(nearby);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetSalon(int id)
    {
        var salon = await _context.Salons
            .Where(s => s.Id == id)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude
            })
            .FirstOrDefaultAsync();

        if (salon == null)
            return NotFound(new { message = "Salon bulunamadı." });

        var salonServices = await _context.Services
            .Where(sv => sv.SalonId == id && sv.StylistId == null)
            .Select(sv => new ServiceDto {
                Id = sv.Id, Name = sv.Name, Price = sv.Price,
                DurationMinutes = sv.DurationMinutes, StylistName = null
            })
            .ToListAsync();

        var stylistSalonServices = await _context.Services
            .Where(sv => sv.SalonId == id && sv.StylistId != null)
            .Join(_context.Users, sv => sv.StylistId, u => u.Id,
                (sv, u) => new ServiceDto {
                    Id = sv.Id, Name = sv.Name, Price = sv.Price,
                    DurationMinutes = sv.DurationMinutes, StylistName = u.FullName
                })
            .ToListAsync();

        var employeeUserIds = await _context.Employees
            .Where(e => e.SalonId == id)
            .Select(e => e.UserId)
            .ToListAsync();

        var legacyStylistServices = await _context.Services
            .Where(sv => sv.StylistId != null && sv.SalonId == null &&
                         employeeUserIds.Contains(sv.StylistId!.Value))
            .Join(_context.Users, sv => sv.StylistId, u => u.Id,
                (sv, u) => new ServiceDto {
                    Id = sv.Id, Name = sv.Name, Price = sv.Price,
                    DurationMinutes = sv.DurationMinutes, StylistName = u.FullName
                })
            .ToListAsync();

        var allServices = salonServices
            .Concat(stylistSalonServices)
            .Concat(legacyStylistServices)
            .ToList();

        return Ok(new {
            salon.Id, salon.Name, salon.Address, salon.Description,
            salon.ImageUrl, salon.OwnerId, salon.Latitude, salon.Longitude,
            services = allServices
        });
    }

    [HttpGet("owner/{ownerId}")]
    public async Task<IActionResult> GetSalonByOwner(int ownerId)
    {
        var salon = await _context.Salons
            .Where(s => s.OwnerId == ownerId)
            .Select(s => new {
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude
            })
            .FirstOrDefaultAsync();

        if (salon == null)
            return NotFound(new { message = "Bu kullanıcıya ait salon bulunamadı." });

        return Ok(salon);
    }

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
                s.Id, s.Name, s.Address, s.Description,
                s.ImageUrl, s.OwnerId, s.Latitude, s.Longitude
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
            salon.Id, salon.Name, salon.Address, salon.Description,
            salon.ImageUrl, salon.OwnerId, salon.Latitude, salon.Longitude
        });
    }

    // YENİ — salon bilgilerini güncelle (adres + koordinat dahil)
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSalon(int id, [FromBody] UpdateSalonRequest req)
    {
        var salon = await _context.Salons.FindAsync(id);
        if (salon == null)
            return NotFound(new { message = "Salon bulunamadı." });

        if (req.Name        != null) salon.Name        = req.Name;
        if (req.Address     != null) salon.Address     = req.Address;
        if (req.Description != null) salon.Description = req.Description;
        if (req.ImageUrl    != null) salon.ImageUrl    = req.ImageUrl;
        if (req.Latitude    != null) salon.Latitude    = req.Latitude;
        if (req.Longitude   != null) salon.Longitude   = req.Longitude;

        await _context.SaveChangesAsync();

        return Ok(new {
            salon.Id, salon.Name, salon.Address, salon.Description,
            salon.ImageUrl, salon.OwnerId, salon.Latitude, salon.Longitude
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

    private static double HaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371.0;
        var dLat = ToRad(lat2 - lat1);
        var dLon = ToRad(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private static double ToRad(double deg) => deg * Math.PI / 180.0;
}

public class UpdateSalonRequest
{
    public string? Name        { get; set; }
    public string? Address     { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl    { get; set; }
    public double? Latitude    { get; set; }
    public double? Longitude   { get; set; }
}

public class ServiceDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }
    public string? StylistName { get; set; }
}
