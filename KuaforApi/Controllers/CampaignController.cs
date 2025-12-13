using KuaforApi.Data;
using KuaforApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CampaignController : ControllerBase
{
    private readonly AppDbContext _context;

    public CampaignController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/campaign
    [HttpGet]
    public async Task<IActionResult> GetCampaigns()
    {
        var campaigns = await _context.Campaigns.ToListAsync();
        return Ok(campaigns);
    }

    // GET: api/campaign/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetCampaign(int id)
    {
        var campaign = await _context.Campaigns.FindAsync(id);
        if (campaign == null)
            return NotFound(new { message = "Kampanya bulunamadı." });

        return Ok(campaign);
    }

    // POST: api/campaign
    [HttpPost]
    public async Task<IActionResult> CreateCampaign([FromBody] Campaign campaign)
    {
        _context.Campaigns.Add(campaign);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCampaign), new { id = campaign.Id }, campaign);
    }
}
