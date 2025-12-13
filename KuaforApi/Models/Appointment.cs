namespace KuaforApi.Models;

public class Appointment
{
    public int Id { get; set; }

    public int CustomerId { get; set; }
    public User? Customer { get; set; }

    public int EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    public int ServiceId { get; set; }
    public Service? Service { get; set; }

    public DateTime Date { get; set; }

    public string Status { get; set; } = "pending";
}
