using Microsoft.AspNetCore.Mvc;
using KuaforApi.Data;
using KuaforApi.Models;
using System.Linq;
using System.Threading.Tasks;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewsController : ControllerBase
    {
        //  1) _db TANIMI
        private readonly AppDbContext _db;

        //  2) CONSTRUCTOR (Dependency Injection)
        public ReviewsController(AppDbContext db)
        {
            _db = db;
        }

        //  3) REQUEST MODEL (ister burada kalsın ister ayrı dosya)
        public class ReviewRequest
        {
            public int Rating { get; set; }
            public string Comment { get; set; } = "";
        }

        //  GET: /api/Reviews  (DB'den listele)
        [HttpGet]
        public IActionResult Get()
        {
            var reviews = _db.Reviews
                .OrderByDescending(r => r.Id)
                .Select(r => new { r.Id, r.Rating, r.Comment, r.CreatedAt })
                .ToList();

            return Ok(reviews);
        }

        //  POST: /api/Reviews  (DB'ye ekle)
        [HttpPost]
        public IActionResult Post([FromBody] ReviewRequest request)
        {
            if (request.Rating < 1 || request.Rating > 5)
                return BadRequest("Rating 1 ile 5 arasında olmalı.");

            if (string.IsNullOrWhiteSpace(request.Comment))
                return BadRequest("Comment boş olamaz.");

            var review = new Review
            {
                Rating = request.Rating,
                Comment = request.Comment.Trim()
                // CreatedAt zaten modelde otomatik setleniyor
            };

            _db.Reviews.Add(review);
            _db.SaveChanges();

            return Ok(new
            {
                Message = "Yorum eklendi",
                review.Id,
                review.Rating,
                review.Comment,
                review.CreatedAt
            });
        }

        //  PUT: /api/Reviews/{id}  (DB'de güncelle)
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] ReviewRequest request)
        {
            var review = await _db.Reviews.FindAsync(id);
            if (review == null) return NotFound("Yorum bulunamadı.");

            if (request.Rating < 1 || request.Rating > 5)
                return BadRequest("Rating 1 ile 5 arasında olmalı.");

            if (string.IsNullOrWhiteSpace(request.Comment))
                return BadRequest("Comment boş olamaz.");

            review.Rating = request.Rating;
            review.Comment = request.Comment.Trim();

            await _db.SaveChangesAsync();

            return Ok(new
            {
                Message = "Yorum güncellendi",
                review.Id,
                review.Rating,
                review.Comment,
                review.CreatedAt
            });
        }

        //  DELETE: /api/Reviews/{id}  (DB'den sil)
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var review = await _db.Reviews.FindAsync(id);
            if (review == null) return NotFound("Yorum bulunamadı.");

            _db.Reviews.Remove(review);
            await _db.SaveChangesAsync();

            return Ok(new { Message = "Yorum silindi", id });
        }
    }
}
