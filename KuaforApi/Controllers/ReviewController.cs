using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewController : ControllerBase
{
    private readonly AppDbContext _context;

    public ReviewController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/review
    [HttpGet]
    public async Task<IActionResult> GetReviews()
    {
        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Include(r => r.Salon)
            .ToListAsync();
        return Ok(reviews);
    }

    // GET: api/review/salon/{salonId}
    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonReviews(int salonId)
    {
        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.SalonId == salonId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();
        return Ok(reviews);
    }

    // POST: api/review
    [HttpPost]
    public async Task<IActionResult> CreateReview([FromBody] Review review)
    {
        review.CreatedAt = DateTime.UtcNow;
        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok(review);
    }
}
