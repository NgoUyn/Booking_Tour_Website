namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("UserLocation")]
    public partial class UserLocation
    {
        [Key]
        public long LocationID { get; set; }

        public int? UserID { get; set; }

        public decimal? Latitude { get; set; }

        public decimal? Longitude { get; set; }

        public double? Accuracy { get; set; }

        public DateTimeOffset? RecordedAt { get; set; }

        public bool? IsCurrent { get; set; }

        public virtual User User { get; set; }
    }
}
