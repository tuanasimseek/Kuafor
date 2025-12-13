namespace KuaforApi.Models;

public class Review
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User User { get; set; }

    public int ServiceId { get; set; }
    public Service Service { get; set; }

    public int Rating { get; set; } // 1–5
    public string Comment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
