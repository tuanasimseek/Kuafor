using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KuaforApi.Data;
using KuaforApi.Models;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AppointmentController : ControllerBase
{
    private readonly AppDbContext _context;

    public AppointmentController(AppDbContext context)
    {
        _context = context;
    }

    // DTO — circular reference önlemek için
    private object MapAppointment(Appointment a) => new
    {
        a.Id,
        a.CustomerId,
        customerName = a.Customer?.FullName ?? "",
        a.StylistId,
        stylistName = a.Stylist?.FullName ?? "",
        a.SalonId,
        salonName = a.Salon?.Name ?? "",
        a.ServiceId,
        serviceName = a.Service?.Name ?? "",
        servicePrice = a.Service?.Price ?? 0,
        a.AppointmentDate,
        a.DurationMinutes,
        a.Status,
        a.Notes,
        a.CreatedAt
    };

    // GET: api/appointment/customer/{customerId}
    // Müşterinin kendi randevuları
    [HttpGet("customer/{customerId}")]
    public async Task<IActionResult> GetCustomerAppointments(int customerId)
    {
        var list = await _context.Appointments
            .Include(a => a.Customer)
            .Include(a => a.Stylist)
            .Include(a => a.Salon)
            .Include(a => a.Service)
            .Where(a => a.CustomerId == customerId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();

        return Ok(list.Select(MapAppointment));
    }

    // GET: api/appointment/stylist/{stylistId}
    // Kuaförün randevuları
    [HttpGet("stylist/{stylistId}")]
    public async Task<IActionResult> GetStylistAppointments(int stylistId)
    {
        var list = await _context.Appointments
            .Include(a => a.Customer)
            .Include(a => a.Stylist)
            .Include(a => a.Salon)
            .Include(a => a.Service)
            .Where(a => a.StylistId == stylistId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();

        return Ok(list.Select(MapAppointment));
    }

    // GET: api/appointment/salon/{salonId}
    // Salon sahibinin tüm randevuları
    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonAppointments(int salonId)
    {
        var list = await _context.Appointments
            .Include(a => a.Customer)
            .Include(a => a.Stylist)
            .Include(a => a.Salon)
            .Include(a => a.Service)
            .Where(a => a.SalonId == salonId)
            .OrderByDescending(a => a.AppointmentDate)
            .ToListAsync();

        return Ok(list.Select(MapAppointment));
    }

    // GET: api/appointment/available-slots?stylistId=X&date=2025-01-15
    // Kuaförün seçilen gün için dolu slotlarını döner
    // Flutter bunu alıp boş slotları hesaplar
    [HttpGet("busy-slots")]
    public async Task<IActionResult> GetBusySlots([FromQuery] int stylistId, [FromQuery] DateTime date)
    {
        var dayStart = date.Date;
        var dayEnd = dayStart.AddDays(1);

        var appointments = await _context.Appointments
            .Where(a =>
                a.StylistId == stylistId &&
                a.AppointmentDate >= dayStart &&
                a.AppointmentDate < dayEnd &&
                a.Status != "İptal Edildi")
            .Select(a => new
            {
                a.AppointmentDate,
                a.DurationMinutes
            })
            .ToListAsync();

        return Ok(appointments);
    }

    // POST: api/appointment
    // Randevu oluştur
    [HttpPost]
    public async Task<IActionResult> CreateAppointment([FromBody] CreateAppointmentRequest request)
    {
        // Çakışma kontrolü: aynı kuaför aynı saatte başka randevusu var mı?
        var newStart = request.AppointmentDate;
        var newEnd = newStart.AddMinutes(request.DurationMinutes);

        var conflict = await _context.Appointments
            .Where(a =>
                a.StylistId == request.StylistId &&
                a.Status != "İptal Edildi" &&
                a.AppointmentDate < newEnd &&
                a.AppointmentDate.AddMinutes(a.DurationMinutes) > newStart)
            .AnyAsync();

        if (conflict)
            return BadRequest(new { message = "Seçilen saat dolu, lütfen başka bir saat seçin." });

        var appointment = new Appointment
        {
            CustomerId = request.CustomerId,
            StylistId = request.StylistId,
            SalonId = request.SalonId,
            ServiceId = request.ServiceId,
            AppointmentDate = request.AppointmentDate,
            DurationMinutes = request.DurationMinutes,
            Status = "Beklemede",
            Notes = request.Notes,
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);
        await _context.SaveChangesAsync();

        // Müşteriye bildirim
        _context.Notifications.Add(new Notification
        {
            Message = $"Randevunuz alındı: {appointment.AppointmentDate:dd.MM.yyyy HH:mm}",
            UserId = appointment.CustomerId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        });

        // Kuaföre bildirim
        _context.Notifications.Add(new Notification
        {
            Message = $"Yeni randevu: {appointment.AppointmentDate:dd.MM.yyyy HH:mm}",
            UserId = appointment.StylistId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        });

        await _context.SaveChangesAsync();

        // Kaydedilen randevuyu include'larla geri döndür
        var saved = await _context.Appointments
            .Include(a => a.Customer)
            .Include(a => a.Stylist)
            .Include(a => a.Salon)
            .Include(a => a.Service)
            .FirstOrDefaultAsync(a => a.Id == appointment.Id);

        return Ok(MapAppointment(saved!));
    }

    // PUT: api/appointment/{id}/status
    // Durum güncelle: Onaylandı / İptal Edildi / Tamamlandı
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Customer)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (appointment == null)
            return NotFound();

        appointment.Status = request.Status;
        await _context.SaveChangesAsync();

        // Müşteriye durum bildirimi
        string msg = request.Status switch
        {
            "Onaylandı" => $"{appointment.AppointmentDate:dd.MM.yyyy HH:mm} tarihli randevunuz onaylandı.",
            "İptal Edildi" => $"{appointment.AppointmentDate:dd.MM.yyyy HH:mm} tarihli randevunuz iptal edildi.",
            "Tamamlandı" => $"{appointment.AppointmentDate:dd.MM.yyyy HH:mm} tarihli randevunuz tamamlandı.",
            _ => $"Randevunuzun durumu güncellendi: {request.Status}"
        };

        _context.Notifications.Add(new Notification
        {
            Message = msg,
            UserId = appointment.CustomerId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        });

        await _context.SaveChangesAsync();

        return Ok(new { message = "Durum güncellendi" });
    }

    // PUT: api/appointment/{id}/cancel
    // Müşteri iptal eder
    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> CancelAppointment(int id, [FromQuery] int customerId)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(a => a.Id == id && a.CustomerId == customerId);

        if (appointment == null)
            return NotFound();

        if (appointment.Status == "Tamamlandı")
            return BadRequest(new { message = "Tamamlanan randevu iptal edilemez." });

        appointment.Status = "İptal Edildi";
        await _context.SaveChangesAsync();

        // Kuaföre bildirim
        _context.Notifications.Add(new Notification
        {
            Message = $"{appointment.AppointmentDate:dd.MM.yyyy HH:mm} tarihli randevu müşteri tarafından iptal edildi.",
            UserId = appointment.StylistId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        });

        await _context.SaveChangesAsync();
        return Ok(new { message = "Randevu iptal edildi" });
    }
}

// Request modelleri
public class CreateAppointmentRequest
{
    public int CustomerId { get; set; }
    public int StylistId { get; set; }
    public int SalonId { get; set; }
    public int ServiceId { get; set; }
    public DateTime AppointmentDate { get; set; }
    public int DurationMinutes { get; set; }
    public string? Notes { get; set; }
}

public class UpdateStatusRequest
{
    public string Status { get; set; } = "";
}