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
            .Select(r => new {
                r.Id,
                r.Rating,
                r.Comment,
                r.CreatedAt,
                r.SalonId,
                r.UserId,
                user = new { r.User!.FullName },
                salon = new { r.Salon!.Name }
            })
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
            .Select(r => new {
                r.Id,
                r.Rating,
                r.Comment,
                r.CreatedAt,
                r.SalonId,
                r.UserId,
                user = new { r.User!.FullName }
            })
            .ToListAsync();
        return Ok(new
        {
            averageRating = reviews.Count == 0 ? 0 : Math.Round(reviews.Average(r => r.Rating), 1),
            count = reviews.Count,
            reviews
        });
    }

    // POST: api/review
    [HttpPost]
    public async Task<IActionResult> CreateReview([FromBody] ReviewRequest request)
    {
        if (request.Rating < 1 || request.Rating > 5)
            return BadRequest(new { message = "Rating 1 ile 5 arasında olmalı." });

        if (string.IsNullOrWhiteSpace(request.Comment))
            return BadRequest(new { message = "Yorum boş olamaz." });

        var salonExists = await _context.Salons.AnyAsync(s => s.Id == request.SalonId);
        if (!salonExists)
            return BadRequest(new { message = "Salon bulunamadı." });

        var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
        if (!userExists)
            return BadRequest(new { message = "Kullanıcı bulunamadı." });

        var hasCompletedAppointment = await _context.Appointments.AnyAsync(a =>
            a.CustomerId == request.UserId &&
            a.SalonId == request.SalonId &&
            (a.Status == "Tamamlandı" || a.Status == "Completed"));

        if (!hasCompletedAppointment)
            return BadRequest(new { message = "Yorum yapabilmek için bu salondan tamamlanmış hizmet almanız gerekir." });

        var review = new Review
        {
            Rating = request.Rating,
            Comment = request.Comment.Trim(),
            SalonId = request.SalonId,
            UserId = request.UserId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok(new {
            review.Id,
            review.Rating,
            review.Comment,
            review.CreatedAt,
            review.SalonId,
            review.UserId
        });
    }
}

public class ReviewRequest
{
    public int Rating { get; set; }
    public string Comment { get; set; } = "";
    public int SalonId { get; set; }
    public int UserId { get; set; }
}
