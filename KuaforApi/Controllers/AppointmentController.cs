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

    // GET: api/appointment
    [HttpGet]
    public async Task<IActionResult> GetAllAppointments()
    {
        var appointments = await _context.Appointments
            .Include(a => a.Service)
            .Include(a => a.Employee)
            .Include(a => a.Customer)
            .ToListAsync();
        return Ok(appointments);
    }

    // GET: api/appointment/user/{userId}
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetUserAppointments(int userId)
    {
        var appointments = await _context.Appointments
            .Include(a => a.Service)
            .Include(a => a.Employee)
            .Include(a => a.Customer)
            .Where(a => a.CustomerId == userId)
            .OrderByDescending(a => a.Date)
            .ToListAsync();
        return Ok(appointments);
    }

    // GET: api/appointment/employee/{employeeId}
    [HttpGet("employee/{employeeId}")]
    public async Task<IActionResult> GetEmployeeAppointments(int employeeId)
    {
        var appointments = await _context.Appointments
            .Include(a => a.Service)
            .Include(a => a.Customer)
            .Where(a => a.EmployeeId == employeeId)
            .OrderByDescending(a => a.Date)
            .ToListAsync();
        return Ok(appointments);
    }

    // POST: api/appointment
    [HttpPost]
    public async Task<IActionResult> CreateAppointment([FromBody] Appointment appointment)
    {
        appointment.Status = "Beklemede";
        _context.Appointments.Add(appointment);
        await _context.SaveChangesAsync();

        // Bildirim oluştur
        var notification = new Notification
        {
            Message = $"Yeni randevunuz: {appointment.Date:dd.MM.yyyy HH:mm}",
            UserId = appointment.CustomerId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        };
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return Ok(appointment);
    }

    // PUT: api/appointment/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateAppointment(int id, [FromBody] Appointment appointment)
    {
        if (id != appointment.Id)
            return BadRequest();

        _context.Entry(appointment).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // PUT: api/appointment/{id}/cancel
    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> CancelAppointment(int id)
    {
        var appointment = await _context.Appointments.FindAsync(id);
        if (appointment == null)
            return NotFound();

        appointment.Status = "İptal Edildi";
        await _context.SaveChangesAsync();

        // İptal bildirimi oluştur
        var notification = new Notification
        {
            Message = $"{appointment.Date:dd.MM.yyyy HH:mm} tarihli randevunuz iptal edildi.",
            UserId = appointment.CustomerId,
            CreatedAt = DateTime.UtcNow,
            IsRead = false
        };
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Randevu iptal edildi" });
    }

    // DELETE: api/appointment/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAppointment(int id)
    {
        var appointment = await _context.Appointments.FindAsync(id);
        if (appointment == null)
            return NotFound();

        _context.Appointments.Remove(appointment);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
