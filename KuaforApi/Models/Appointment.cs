namespace KuaforApi.Models
{
    public class Appointment
    {
        public int Id { get; set; }
        public int CustomerId { get; set; }
        public User? Customer { get; set; }

        public int StylistId { get; set; }      // Kuaförün User.Id'si
        public User? Stylist { get; set; }

        public int SalonId { get; set; }
        public Salon? Salon { get; set; }

        public int ServiceId { get; set; }
        public Service? Service { get; set; }

        public DateTime AppointmentDate { get; set; }  // Tarih + saat birlikte
        public int DurationMinutes { get; set; }

        public string Status { get; set; } = "Beklemede"; // Beklemede / Onaylandı / İptal Edildi / Tamamlandı

        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}