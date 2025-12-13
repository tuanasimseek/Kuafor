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

    // GET: api/employee/salon/{salonId}
    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonEmployees(int salonId)
    {
        var employees = await _context.Employees
            .Where(e => e.SalonId == salonId)
            .ToListAsync();
        return Ok(employees);
    }

    // GET: api/employee/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetEmployee(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return NotFound();
        return Ok(employee);
    }

    // POST: api/employee
    [HttpPost]
    public async Task<IActionResult> CreateEmployee([FromBody] Employee employee)
    {
        var salonExists = await _context.Salons.AnyAsync(s => s.Id == employee.SalonId);
        if (!salonExists)
            return BadRequest(new { message = "Salon bulunamadı" });

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();
        return Ok(employee);
    }

    // PUT: api/employee/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] Employee employee)
    {
        if (id != employee.Id)
            return BadRequest();

        _context.Entry(employee).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/employee/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return NotFound();

        _context.Employees.Remove(employee);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
