namespace KuaforApi.Models;

public class Salon
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }

    public int OwnerId { get; set; }
    public User? Owner { get; set; }

    public List<Employee>? Employees { get; set; }
    public List<Service>? Services { get; set; }
}

