namespace KuaforApi.Models;

public class Service
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }

    // Salon sahibi tarafından eklenen hizmetler için
    public int? SalonId { get; set; }
    public Salon? Salon { get; set; }

    // Kuaför tarafından eklenen hizmetler için
    public int? StylistId { get; set; }
    public User? Stylist { get; set; }
}