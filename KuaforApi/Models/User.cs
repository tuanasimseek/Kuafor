namespace KuaforApi.Models;

public class User
{
    public int Id { get; set; }

    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;

    // admin / owner / employee / customer
    public string Role { get; set; } = "customer";  

    // Kuaförün uzmanlık alanı
    public string? Specialty { get; set; }

    // Profil fotoğrafı
    public string? ProfileImageUrl { get; set; }

    // Puan ortalaması
    public double Rating { get; set; } = 0;
}
