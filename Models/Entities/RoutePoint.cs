namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("RoutePoint")]
    public partial class RoutePoint
    {
        public int RoutePointID { get; set; }

        public int? RouteID { get; set; }

        public long? PlaceID { get; set; }

        public int? OrderInRoute { get; set; }

        public decimal? DistanceKm { get; set; }

        public int? DurationMin { get; set; }

        public virtual Place Place { get; set; }

        public virtual Route Route { get; set; }
    }
}
