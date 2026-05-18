namespace KuaforApi.Models;

public class StylistAvailability
{
    public int Id { get; set; }
    public int StylistId { get; set; }
    public User? Stylist { get; set; }
    public int DayOfWeek { get; set; }
    public bool IsOpen { get; set; } = true;
    public TimeSpan OpenTime { get; set; } = new(9, 0, 0);
    public TimeSpan CloseTime { get; set; } = new(18, 0, 0);
}
