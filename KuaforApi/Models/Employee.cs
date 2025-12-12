namespace KuaforApi.Models;

public class Employee
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User? User { get; set; }

    public int SalonId { get; set; }
    public Salon? Salon { get; set; }
}
