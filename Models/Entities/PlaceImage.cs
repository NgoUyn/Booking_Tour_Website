namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("PlaceImage")]
    public partial class PlaceImage
    {
        [Key]
        public int ImageID { get; set; }

        public long? PlaceID { get; set; }

        [StringLength(255)]
        public string Url { get; set; }

        public bool? IsCover { get; set; }

        public int? UploadedBy { get; set; }

        public DateTimeOffset? CreatedAt { get; set; }

        public virtual Place Place { get; set; }

        public virtual User User { get; set; }
    }
}
