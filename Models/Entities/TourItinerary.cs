namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("TourItinerary")]
    public partial class TourItinerary
    {
        [Key]
        public int ItineraryID { get; set; }

        public int? TourID { get; set; }

        public int? DayNumber { get; set; }

        [StringLength(255)]
        public string Title { get; set; }

        public string Description { get; set; }

        public virtual Tour Tour { get; set; }
    }
}
