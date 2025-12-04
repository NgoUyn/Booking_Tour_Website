namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Tour")]
    public partial class Tour
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Tour()
        {
            CartItems = new HashSet<CartItem>();
            OrderDetails = new HashSet<OrderDetail>();
            TourItineraries = new HashSet<TourItinerary>();
            TourPlaces = new HashSet<TourPlace>();
        }

        public int TourID { get; set; }

        [Required]
        [StringLength(255)]
        public string TourName { get; set; }

        public string Description { get; set; }

        public decimal? Price { get; set; }

        [StringLength(50)]
        public string Duration { get; set; }

        public long? StartLocation { get; set; }

        public long? EndLocation { get; set; }

        public int? TotalSlots { get; set; }

        public int? AvailableSlots { get; set; }

        public int? CategoryID { get; set; }

        [StringLength(255)]
        public string AvatarUrl { get; set; }

        public int? Status { get; set; }

        public DateTime? CreatedAt { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<CartItem> CartItems { get; set; }

        public virtual Category Category { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<OrderDetail> OrderDetails { get; set; }

        public virtual Place Place { get; set; }

        public virtual Place Place1 { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<TourItinerary> TourItineraries { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<TourPlace> TourPlaces { get; set; }
    }
}
