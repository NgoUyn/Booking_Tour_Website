namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Route")]
    public partial class Route
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Route()
        {
            RoutePoints = new HashSet<RoutePoint>();
        }

        public int RouteID { get; set; }

        public int? UserID { get; set; }

        [StringLength(255)]
        public string RouteName { get; set; }

        public DateTimeOffset? CreatedAt { get; set; }

        public virtual User User { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RoutePoint> RoutePoints { get; set; }
    }
}
