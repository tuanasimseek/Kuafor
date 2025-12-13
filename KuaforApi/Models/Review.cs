namespace KuaforApi.Models;

public class Review
{
    public int Id { get; set; }
    public int Rating { get; set; } // 1-5 arası
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public int UserId { get; set; }
    public User? User { get; set; }
    
    public int SalonId { get; set; }
    public Salon? Salon { get; set; }
}
