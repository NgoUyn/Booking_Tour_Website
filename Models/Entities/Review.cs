namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Review")]
    public partial class Review
    {
        public long ReviewID { get; set; }

        public long? PlaceID { get; set; }

        public int? UserID { get; set; }

        public byte? Rating { get; set; }

        public string Comment { get; set; }

        public DateTimeOffset? CreatedAt { get; set; }

        public virtual Place Place { get; set; }

        public virtual User User { get; set; }
    }
}
