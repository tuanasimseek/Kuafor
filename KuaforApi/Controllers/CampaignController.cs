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

    // POST: api/campaign
    [HttpPost]
    public async Task<IActionResult> CreateCampaign(Campaign campaign)
    {
        _context.Campaigns.Add(campaign);
        await _context.SaveChangesAsync();
        return Ok(campaign);
    }
}
