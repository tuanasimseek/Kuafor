<<<<<<< HEAD
namespace KuaforApi.Models
{
    public class Campaign
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public int DiscountPercent { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
=======
namespace KuaforApi.Models;

public class Campaign
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal? DiscountPercentage { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    
    public int? SalonId { get; set; }
    public Salon? Salon { get; set; }
>>>>>>> bfce3bbeaa8220ef7a117b52532cece3251f9ef1
}
