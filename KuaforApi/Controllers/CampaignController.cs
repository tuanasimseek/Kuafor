using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KuaforApi.Data;
using KuaforApi.Models;

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
    public async Task<IActionResult> GetAllCampaigns()
    {
        var campaigns = await _context.Campaigns
            .Where(c => c.IsActive)
            .OrderByDescending(c => c.StartDate)
            .ToListAsync();
        return Ok(campaigns);
    }

    // GET: api/campaign/salon/{salonId}
    [HttpGet("salon/{salonId}")]
    public async Task<IActionResult> GetSalonCampaigns(int salonId)
    {
        var campaigns = await _context.Campaigns
            .Where(c => c.SalonId == salonId && c.IsActive)
            .OrderByDescending(c => c.StartDate)
            .ToListAsync();
        return Ok(campaigns);
    }

    // GET: api/campaign/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetCampaign(int id)
    {
        var campaign = await _context.Campaigns.FindAsync(id);
        if (campaign == null)
            return NotFound();
        return Ok(campaign);
    }

    // POST: api/campaign
    [HttpPost]
    public async Task<IActionResult> CreateCampaign([FromBody] Campaign campaign)
    {
        _context.Campaigns.Add(campaign);
        await _context.SaveChangesAsync();
        return Ok(campaign);
    }

    // PUT: api/campaign/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCampaign(int id, [FromBody] Campaign campaign)
    {
        if (id != campaign.Id)
            return BadRequest();

        _context.Entry(campaign).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/campaign/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCampaign(int id)
    {
        var campaign = await _context.Campaigns.FindAsync(id);
        if (campaign == null)
            return NotFound();

        _context.Campaigns.Remove(campaign);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // PUT: api/campaign/{id}/deactivate
    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> DeactivateCampaign(int id)
    {
        var campaign = await _context.Campaigns.FindAsync(id);
        if (campaign == null)
            return NotFound();

        campaign.IsActive = false;
        await _context.SaveChangesAsync();
        return Ok(new { message = "Kampanya devre dışı bırakıldı" });
    }
}
