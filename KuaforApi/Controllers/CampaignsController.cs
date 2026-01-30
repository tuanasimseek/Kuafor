using Microsoft.AspNetCore.Mvc;
using KuaforApi.Data;
using KuaforApi.Models;
using System.Linq;

namespace KuaforApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CampaignsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public CampaignsController(AppDbContext db)
        {
            _db = db;
        }

        // GET: /api/Campaigns
        [HttpGet]
        public IActionResult Get()
        {
            var campaigns = _db.Campaigns
                .OrderByDescending(c => c.CreatedAt)
                .ToList();

            return Ok(campaigns);
        }

        // POST: /api/Campaigns
        [HttpPost]
        public IActionResult Post([FromBody] Campaign campaign)
        {
            if (string.IsNullOrWhiteSpace(campaign.Title))
                return BadRequest("Başlık (Title) boş olamaz.");

            if (campaign.DiscountPercent < 0 || campaign.DiscountPercent > 100)
                return BadRequest("DiscountPercent 0-100 arasında olmalı.");

            campaign.Title = campaign.Title.Trim();
            campaign.Description = campaign.Description?.Trim() ?? "";

            _db.Campaigns.Add(campaign);
            _db.SaveChanges();

            return Ok(new
            {
                Message = "Kampanya eklendi",
                campaign.Id,
                campaign.Title,
                campaign.DiscountPercent,
                campaign.CreatedAt
            });
        }
    }
}

