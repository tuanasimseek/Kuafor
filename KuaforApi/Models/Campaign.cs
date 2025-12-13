using System.ComponentModel.DataAnnotations;

namespace KuaforApi.Models;

public class Campaign
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Title { get; set; }

    public string? Description { get; set; }

    public double DiscountRate { get; set; } // %10, %20 gibi

    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }

    // Kampanyayı oluşturan salon
    public int SalonId { get; set; }
    public Salon Salon { get; set; }
}
