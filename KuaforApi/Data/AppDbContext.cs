using Microsoft.EntityFrameworkCore;
using KuaforApi.Models;

namespace KuaforApi.Data
{
    public class AppDbContext : DbContext
    {
<<<<<<< HEAD
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Review> Reviews => Set<Review>();
        public DbSet<Campaign> Campaigns { get; set; }

=======
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) 
        { 
        }

        // Kullanıcı
        public DbSet<User> Users { get; set; } = null!;

        // Salon yapısı
        public DbSet<Salon> Salons { get; set; } = null!;
        public DbSet<Employee> Employees { get; set; } = null!;
        public DbSet<Service> Services { get; set; } = null!;
        public DbSet<Appointment> Appointments { get; set; } = null!;

        // Sema modülü
        public DbSet<Campaign> Campaigns { get; set; } = null!;
        public DbSet<Review> Reviews { get; set; } = null!;
        public DbSet<Notification> Notifications { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // PostgreSQL için DateTime'ı UTC olarak kaydet
            AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
        }
>>>>>>> bfce3bbeaa8220ef7a117b52532cece3251f9ef1
    }
}
