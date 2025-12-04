using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;
using System.Linq;

namespace Tour_Website.Models.Entities
{
    public partial class TourProject_Database1 : DbContext
    {
        public TourProject_Database1()
            : base("name=TourProject_Database1")
        {
        }

        public virtual DbSet<AdminRole> AdminRoles { get; set; }
        public virtual DbSet<AdminStaff> AdminStaffs { get; set; }
        public virtual DbSet<AuditLog> AuditLogs { get; set; }
        public virtual DbSet<Cart> Carts { get; set; }
        public virtual DbSet<CartItem> CartItems { get; set; }
        public virtual DbSet<Category> Categories { get; set; }
        public virtual DbSet<Order> Orders { get; set; }
        public virtual DbSet<OrderDetail> OrderDetails { get; set; }
        public virtual DbSet<Payment> Payments { get; set; }
        public virtual DbSet<Place> Places { get; set; }
        public virtual DbSet<PlaceImage> PlaceImages { get; set; }
        public virtual DbSet<Review> Reviews { get; set; }
        public virtual DbSet<Route> Routes { get; set; }
        public virtual DbSet<RoutePoint> RoutePoints { get; set; }
        public virtual DbSet<sysdiagram> sysdiagrams { get; set; }
        public virtual DbSet<Tour> Tours { get; set; }
        public virtual DbSet<TourItinerary> TourItineraries { get; set; }
        public virtual DbSet<TourPlace> TourPlaces { get; set; }
        public virtual DbSet<UserLocation> UserLocations { get; set; }
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<Voucher> Vouchers { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AdminRole>()
                .HasMany(e => e.AdminStaffs)
                .WithRequired(e => e.AdminRole)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<CartItem>()
                .Property(e => e.UnitPrice)
                .HasPrecision(12, 2);

            modelBuilder.Entity<Order>()
                .Property(e => e.TotalAmount)
                .HasPrecision(12, 2);

            modelBuilder.Entity<Order>()
                .Property(e => e.FinalAmount)
                .HasPrecision(12, 2);

            modelBuilder.Entity<OrderDetail>()
                .Property(e => e.UnitPrice)
                .HasPrecision(12, 2);

            modelBuilder.Entity<Payment>()
                .Property(e => e.Amount)
                .HasPrecision(12, 2);

            modelBuilder.Entity<Place>()
                .Property(e => e.Longitude)
                .HasPrecision(10, 7);

            modelBuilder.Entity<Place>()
                .Property(e => e.Latitude)
                .HasPrecision(10, 7);

            modelBuilder.Entity<Place>()
                .Property(e => e.AvgRating)
                .HasPrecision(3, 2);

            modelBuilder.Entity<Place>()
                .HasMany(e => e.Tours)
                .WithOptional(e => e.Place)
                .HasForeignKey(e => e.EndLocation);

            modelBuilder.Entity<Place>()
                .HasMany(e => e.Tours1)
                .WithOptional(e => e.Place1)
                .HasForeignKey(e => e.StartLocation);

            modelBuilder.Entity<Place>()
                .HasMany(e => e.TourPlaces)
                .WithRequired(e => e.Place)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<RoutePoint>()
                .Property(e => e.DistanceKm)
                .HasPrecision(6, 2);

            modelBuilder.Entity<Tour>()
                .HasMany(e => e.TourPlaces)
                .WithRequired(e => e.Tour)
                .WillCascadeOnDelete(false);

            modelBuilder.Entity<UserLocation>()
                .Property(e => e.Latitude)
                .HasPrecision(10, 7);

            modelBuilder.Entity<UserLocation>()
                .Property(e => e.Longitude)
                .HasPrecision(10, 7);

            modelBuilder.Entity<User>()
                .Property(e => e.Phone)
                .IsUnicode(false);

            modelBuilder.Entity<User>()
                .Property(e => e.TotalSpent)
                .HasPrecision(12, 2);

            modelBuilder.Entity<User>()
                .Property(e => e.MemberLevel)
                .IsUnicode(false);

            modelBuilder.Entity<User>()
                .HasMany(e => e.Places)
                .WithOptional(e => e.User)
                .HasForeignKey(e => e.CreatedBy);

            modelBuilder.Entity<User>()
                .HasMany(e => e.PlaceImages)
                .WithOptional(e => e.User)
                .HasForeignKey(e => e.UploadedBy);

            modelBuilder.Entity<Voucher>()
                .Property(e => e.DiscountPercent)
                .HasPrecision(5, 2);
        }
    }
}
