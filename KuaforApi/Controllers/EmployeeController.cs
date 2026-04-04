using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmployeeController : ControllerBase
{
    private readonly AppDbContext _context;

    public EmployeeController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonEmployees(int salonId)
    {
        var employees = await _context.Employees
            .Where(e => e.SalonId == salonId)
            .Join(
                _context.Users,
                e => e.UserId,
                u => u.Id,
                (e, u) => new {
                    e.Id,
                    e.UserId,
                    e.SalonId,
                    FullName = u.FullName,
                    Email = u.Email
                }
            )
            .ToListAsync();
        return Ok(employees);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetEmployee(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return NotFound();
        return Ok(employee);
    }

    // Email ile kullanıcı ara — sadece Hairdresser rolündekiler eklenebilir
    [HttpGet("find-user")]
    public async Task<IActionResult> FindUserByEmail([FromQuery] string email)
    {
        var user = await _context.Users
            .Where(u => u.Email == email)
            .Select(u => new { u.Id, u.FullName, u.Email, u.Role })
            .FirstOrDefaultAsync();

        if (user == null)
            return NotFound(new { message = "Bu email ile kayıtlı kullanıcı bulunamadı." });

        if (user.Role != "Hairdresser")
            return BadRequest(new { message = "Bu kullanıcı kuaför rolünde değil." });

        return Ok(user);
    }

    [HttpPost]
    public async Task<IActionResult> CreateEmployee([FromBody] Employee employee)
    {
        var salonExists = await _context.Salons.AnyAsync(s => s.Id == employee.SalonId);
        if (!salonExists)
            return BadRequest(new { message = "Salon bulunamadı" });

        var userExists = await _context.Users.AnyAsync(u => u.Id == employee.UserId);
        if (!userExists)
            return BadRequest(new { message = "Kullanıcı bulunamadı" });

        var alreadyExists = await _context.Employees
            .AnyAsync(e => e.UserId == employee.UserId && e.SalonId == employee.SalonId);
        if (alreadyExists)
            return BadRequest(new { message = "Bu kullanıcı zaten bu salona kayıtlı." });

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        var user = await _context.Users
            .Where(u => u.Id == employee.UserId)
            .Select(u => new { u.FullName, u.Email })
            .FirstAsync();

        return Ok(new {
            employee.Id,
            employee.UserId,
            employee.SalonId,
            user.FullName,
            user.Email
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return NotFound();

        _context.Employees.Remove(employee);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Çalışan silindi." });
    }
}