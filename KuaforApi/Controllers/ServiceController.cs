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

    // GET: api/service/salon/{salonId}
    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonServices(int salonId)
    {
        var services = await _context.Services
            .Where(s => s.SalonId == salonId)
            .ToListAsync();
        return Ok(services);
    }

    // POST: api/service
    [HttpPost]
    public async Task<IActionResult> CreateService([FromBody] Service service)
    {
        var salonExists = await _context.Salons.AnyAsync(s => s.Id == service.SalonId);
        if (!salonExists)
            return BadRequest(new { message = "Salon bulunamadı" });

        _context.Services.Add(service);
        await _context.SaveChangesAsync();
        return Ok(service);
    }

    // PUT: api/service/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateService(int id, [FromBody] Service service)
    {
        if (id != service.Id)
            return BadRequest();

        _context.Entry(service).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/service/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteService(int id)
    {
        var service = await _context.Services.FindAsync(id);
        if (service == null)
            return NotFound();

        _context.Services.Remove(service);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
