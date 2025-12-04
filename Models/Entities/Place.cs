namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Place")]
    public partial class Place
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Place()
        {
            PlaceImages = new HashSet<PlaceImage>();
            Reviews = new HashSet<Review>();
            RoutePoints = new HashSet<RoutePoint>();
            Tours = new HashSet<Tour>();
            Tours1 = new HashSet<Tour>();
            TourPlaces = new HashSet<TourPlace>();
        }

        public long PlaceID { get; set; }

        [Required]
        [StringLength(255)]
        public string Name { get; set; }

        public int? CategoryID { get; set; }

        public string Description { get; set; }

        [StringLength(255)]
        public string Address { get; set; }

        public decimal? Longitude { get; set; }

        public decimal? Latitude { get; set; }

        [StringLength(255)]
        public string Source { get; set; }

        [StringLength(100)]
        public string ExternalID { get; set; }

        public decimal? AvgRating { get; set; }

        public int? RatingCount { get; set; }

        public int? CreatedBy { get; set; }

        public DateTimeOffset? CreatedAt { get; set; }

        public bool? IsActive { get; set; }

        public virtual Category Category { get; set; }

        public virtual User User { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<PlaceImage> PlaceImages { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Review> Reviews { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RoutePoint> RoutePoints { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Tour> Tours { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Tour> Tours1 { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<TourPlace> TourPlaces { get; set; }
    }
}
