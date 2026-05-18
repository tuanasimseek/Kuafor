using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AvailabilityController : ControllerBase
{
    private readonly AppDbContext _context;

    public AvailabilityController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("stylist/{stylistId}")]
    public async Task<IActionResult> GetStylistAvailability(int stylistId)
    {
        var rows = await _context.StylistAvailabilities
            .Where(a => a.StylistId == stylistId)
            .OrderBy(a => a.DayOfWeek)
            .ToListAsync();

        if (rows.Count == 0)
            rows = DefaultAvailability(stylistId);

        return Ok(rows.Select(Map));
    }

    [HttpPut("stylist/{stylistId}")]
    public async Task<IActionResult> SaveStylistAvailability(int stylistId, [FromBody] List<AvailabilityRequest> requests)
    {
        if (!await _context.Users.AnyAsync(u => u.Id == stylistId))
            return BadRequest(new { message = "Stilist bulunamadı." });

        foreach (var req in requests)
        {
            if (req.DayOfWeek < 1 || req.DayOfWeek > 7)
                return BadRequest(new { message = "Gün değeri 1-7 arasında olmalıdır." });

            if (!TimeSpan.TryParse(req.OpenTime, out var openTime) ||
                !TimeSpan.TryParse(req.CloseTime, out var closeTime))
                return BadRequest(new { message = "Saat formatı geçersiz. HH:mm kullanın." });

            if (req.IsOpen && closeTime <= openTime)
                return BadRequest(new { message = "Kapanış saati açılış saatinden sonra olmalıdır." });

            var existing = await _context.StylistAvailabilities
                .FirstOrDefaultAsync(a => a.StylistId == stylistId && a.DayOfWeek == req.DayOfWeek);

            if (existing == null)
            {
                existing = new StylistAvailability
                {
                    StylistId = stylistId,
                    DayOfWeek = req.DayOfWeek
                };
                _context.StylistAvailabilities.Add(existing);
            }

            existing.IsOpen = req.IsOpen;
            existing.OpenTime = openTime;
            existing.CloseTime = closeTime;
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "Çalışma saatleri kaydedildi." });
    }

    private static object Map(StylistAvailability row) => new
    {
        row.Id,
        row.StylistId,
        row.DayOfWeek,
        row.IsOpen,
        openTime = row.OpenTime.ToString(@"hh\:mm"),
        closeTime = row.CloseTime.ToString(@"hh\:mm")
    };

    private static List<StylistAvailability> DefaultAvailability(int stylistId)
    {
        return Enumerable.Range(1, 7).Select(day => new StylistAvailability
        {
            StylistId = stylistId,
            DayOfWeek = day,
            IsOpen = day <= 5,
            OpenTime = new TimeSpan(9, 0, 0),
            CloseTime = new TimeSpan(18, 0, 0)
        }).ToList();
    }
}

public class AvailabilityRequest
{
    public int DayOfWeek { get; set; }
    public bool IsOpen { get; set; }
    public string OpenTime { get; set; } = "09:00";
    public string CloseTime { get; set; } = "18:00";
}
