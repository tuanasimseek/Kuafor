using KuaforApi.Models;
using Microsoft.EntityFrameworkCore;

namespace KuaforApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Salon> Salons { get; set; }
        public DbSet<Employee> Employees { get; set; }
        public DbSet<Service> Services { get; set; }
        public DbSet<Appointment> Appointments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Salon Sahibi → Salon (1 owner : n salon)
            modelBuilder.Entity<Salon>()
                .HasOne(s => s.Owner)
                .WithMany()
                .HasForeignKey(s => s.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);

            // Employee → Salon
            modelBuilder.Entity<Employee>()
                .HasOne(e => e.Salon)
                .WithMany(s => s.Employees)
                .HasForeignKey(e => e.SalonId);

            // Employee → User
            modelBuilder.Entity<Employee>()
                .HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId);

            // Service → Salon
            modelBuilder.Entity<Service>()
                .HasOne(s => s.Salon)
                .WithMany(salon => salon.Services)
                .HasForeignKey(s => s.SalonId);
        }
    }
}
