namespace KuaforApi.Models;

public class User
{
    public int Id { get; set; }

    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Username { get; set; }
    public string PasswordHash { get; set; } = string.Empty;

    // owner / employee / customer
    public string Role { get; set; } = "Customer";  

    // Kuaförün uzmanlık alanı
    public string? Specialty { get; set; }

    // Profil fotoğrafı
    public string? ProfileImageUrl { get; set; }

    // Puan ortalaması
    public double Rating { get; set; } = 0;

    public string? AuthProvider { get; set; }
    public string? ProviderId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
